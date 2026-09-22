-- Fork of sidebar.nvim builtin/git.lua fixing two race conditions that
-- blank the section during navigation:
--   1. builtin used module-global loclist_items/finished reset at the start
--      of every async cycle -- overlapping cycles clobbered each other and
--      set_items fired with partial/empty results
--   2. builtin's libuv exit callback could run before stdout was drained,
--      silently dropping output
-- Fixes: per-cycle local results + vim.system() (atomic stdout delivery on
-- process exit) + a generation counter so only the newest cycle may publish.

local utils = require("sidebar-nvim.utils")
local sidebar = require("sidebar-nvim")
local Loclist = require("sidebar-nvim.components.loclist")
local Debouncer = require("sidebar-nvim.debouncer")
local config = require("sidebar-nvim.config")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local loclist = Loclist:new({})

-- Make sure all groups exist
loclist:add_group("Staged")
loclist:add_group("Unstaged")
loclist:add_group("Unmerged")
loclist:add_group("Untracked")

-- Only the cycle whose gen matches this value is allowed to publish results
local generation = 0

-- parse line from git diff --numstat into a loclist item (appends to items)
local function parse_git_diff(items, group, line)
    local t = vim.split(line, "\t")
    local added, removed, filepath = t[1], t[2], t[3]
    if filepath == nil or filepath == "" then
        return
    end

    local extension = filepath:match("^.+%.(.+)$")
    local fileicon = ""
    local filehighlight = "SidebarNvimGitStatusFileIcon"

    if has_devicons and devicons.has_loaded() then
        local icon, highlight = devicons.get_icon(filepath, extension)
        if icon then
            fileicon = icon
            filehighlight = highlight
        end
    end

    loclist:open_group(group)
    table.insert(items, {
        group = group,
        left = {
            { text = fileicon .. " ", hl = filehighlight },
            { text = utils.shortest_path(filepath) .. " ", hl = "SidebarNvimGitStatusFileName" },
            { text = added, hl = "SidebarNvimGitStatusDiffAdded" },
            { text = ", " },
            { text = removed, hl = "SidebarNvimGitStatusDiffRemoved" },
        },
        filepath = filepath,
    })
end

-- parse line from git status --porcelain into a loclist item (appends to items)
local function parse_git_status(items, group, line)
    local striped = line:match("^%s*(.-)%s*$")
    local status = striped:sub(0, 2)
    local filepath = striped:sub(3, -1):match("^%s*(.-)%s*$")

    if status ~= "??" or filepath == "" then
        return
    end

    local extension = filepath:match("^.+%.(.+)$")
    local fileicon = ""
    if has_devicons and devicons.has_loaded() then
        local icon = devicons.get_icon(filepath, extension)
        if icon then
            fileicon = icon
        end
    end

    loclist:open_group(group)
    table.insert(items, {
        group = group,
        left = {
            { text = fileicon .. " ", hl = "SidebarNvimGitStatusFileIcon" },
            { text = utils.shortest_path(filepath), hl = "SidebarNvimGitStatusFileName" },
        },
        filepath = filepath,
    })
end

local git_jobs = {
    { group = "Staged", args = { "diff", "--numstat", "--staged", "--diff-filter=u" }, parse = parse_git_diff },
    { group = "Unstaged", args = { "diff", "--numstat", "--diff-filter=u" }, parse = parse_git_diff },
    { group = "Unmerged", args = { "diff", "--numstat", "--diff-filter=U" }, parse = parse_git_diff },
    { group = "Untracked", args = { "status", "--porcelain" }, parse = parse_git_status },
}

local function async_update(_)
    generation = generation + 1
    local gen = generation
    -- Per-cycle locals: a newer cycle can never clobber these
    local items = {}
    local remaining = #git_jobs

    for _, job in ipairs(git_jobs) do
        local cmd = { "git" }
        vim.list_extend(cmd, job.args)

        local ok = pcall(vim.system, cmd, { text = true, cwd = vim.uv.cwd() }, function(out)
            vim.schedule(function()
                -- A newer cycle started while we were running: drop our results
                if gen ~= generation then
                    return
                end

                if out.code == 0 and out.stdout and out.stdout ~= "" then
                    for _, line in ipairs(vim.split(out.stdout, "\n")) do
                        if line ~= "" then
                            job.parse(items, job.group, line)
                        end
                    end
                end

                remaining = remaining - 1
                if remaining == 0 then
                    -- Publish once, atomically, only for the newest generation
                    loclist:set_items(items, { remove_groups = false })
                end
            end)
        end)

        if not ok then
            remaining = remaining - 1
        end
    end
end

local async_update_debounced = Debouncer:new(async_update, 1000)

local function open_file(line)
    local location = loclist:get_location_at(line)
    if location == nil then
        return
    end
    vim.cmd("wincmd p")
    vim.cmd("e " .. vim.fn.fnameescape(location.filepath))
end

local section = {
    title = "Git Status",
    icon = config["git"].icon,
    setup = function(ctx)
        vim.api.nvim_create_autocmd("ShellCmdPost", {
            group = vim.api.nvim_create_augroup("sidebar_nvim_git_status_update", { clear = true }),
            callback = function()
                require("plugins.sidebar-git").update()
            end,
        })
        vim.api.nvim_create_autocmd("BufLeave", {
            group = "sidebar_nvim_git_status_update",
            pattern = "term://*",
            callback = function()
                require("plugins.sidebar-git").update()
            end,
        })
        async_update_debounced:call(ctx)
    end,
    update = function(ctx)
        if not ctx then
            ctx = { width = sidebar.get_width() }
        end
        async_update_debounced:call(ctx)
    end,
    draw = function(ctx)
        local lines = {}
        local hl = {}

        loclist:draw(ctx, lines, hl)

        if #lines == 0 then
            lines = { "<no changes>" }
        end

        return { lines = lines, hl = hl }
    end,
    highlights = {
        groups = {},
        links = {
            SidebarNvimGitStatusFileName = "SidebarNvimNormal",
            SidebarNvimGitStatusFileIcon = "SidebarNvimSectionTitle",
            SidebarNvimGitStatusDiffAdded = "DiffAdded",
            SidebarNvimGitStatusDiffRemoved = "DiffRemoved",
        },
    },
    bindings = {
        ["e"] = open_file,
        ["<CR>"] = open_file,
        -- stage files
        ["s"] = function(line)
            local location = loclist:get_location_at(line)
            if location == nil then
                return
            end
            utils.async_cmd("git", { "add", location.filepath }, function()
                async_update_debounced:call()
            end)
        end,
        -- unstage files
        ["u"] = function(line)
            local location = loclist:get_location_at(line)
            if location == nil then
                return
            end
            utils.async_cmd("git", { "restore", "--staged", location.filepath }, function()
                async_update_debounced:call()
            end)
        end,
    },
}

return section
