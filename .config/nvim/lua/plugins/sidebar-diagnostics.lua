-- Forked from sidebar-nvim/builtin/diagnostics.lua.
--
-- Why forked: the builtin calls vim.diagnostic.get() with NO buffer argument
-- on every DiagnosticChanged event. vim.diagnostic.get() deep-copies every
-- diagnostic of every buffer -- with jdtls on large Java workspaces this is
-- seconds of vim.deepcopy on the main thread (profiled: ~9s freeze after
-- JUnit runs, because nvim-dap's session-end diagnostic reset fires a burst
-- of DiagnosticChanged events).
--
-- Changes vs builtin:
--   1. Scoped to the CURRENT buffer only: vim.diagnostic.get(bufnr) -- cost
--      is bounded by one file's diagnostics.
--   2. Debounced: DiagnosticChanged bursts (dap session end, LSP publish)
--      coalesce into one update 300ms after the last event.
--   3. BufEnter refresh so the section follows the active file.
--   4. Dropped the buggy open_bufs[bufnr] check (nvim_list_bufs() returns an
--      array; indexing it by bufnr was wrong in the builtin).

local Loclist = require("sidebar-nvim.components.loclist")
local config = require("sidebar-nvim.config")

local loclist = Loclist:new({})

local severity_level = { "Error", "Warning", "Info", "Hint" }
local icons = { "", "", "", "" }
local use_icons = true

local function get_diagnostics()
    local current_buf = vim.api.nvim_get_current_buf()

    -- Don't retarget while focus is in the sidebar or floating windows --
    -- keep showing the last real file's diagnostics.
    if vim.bo[current_buf].buftype ~= "" then
        return
    end

    local current_buf_filepath = vim.api.nvim_buf_get_name(current_buf)
    local current_buf_filename = vim.fn.fnamemodify(current_buf_filepath, ":t")
    if current_buf_filename == "" then
        return
    end

    -- Current buffer ONLY -- this is the whole point of the fork.
    local diagnostics = vim.diagnostic.get(current_buf)
    local loclist_items = {}

    for _, diag in ipairs(diagnostics) do
        local message = diag.message:gsub("\n", " ")
        local severity = diag.severity
        local level = severity_level[severity]
        local icon = icons[severity]

        if not use_icons then
            icon = level
        end

        table.insert(loclist_items, {
            group = current_buf_filename,
            left = {
                { text = icon .. " ", hl = "SidebarNvimLspDiagnostics" .. level },
                { text = diag.lnum + 1, hl = "SidebarNvimLspDiagnosticsLineNumber" },
                { text = ":" },
                { text = (diag.col + 1) .. " ", hl = "SidebarNvimLspDiagnosticsColNumber" },
                { text = message },
            },
            lnum = diag.lnum + 1,
            col = diag.col + 1,
            filepath = current_buf_filepath,
        })
    end

    loclist:set_items(loclist_items, { remove_groups = true })
    if loclist.groups[current_buf_filename] ~= nil then
        loclist.groups[current_buf_filename].is_closed = false
    end
end

-- Debounce: coalesce DiagnosticChanged bursts into one update.
local debounce_timer = nil
local function debounced_update()
    if debounce_timer then
        debounce_timer:stop()
        debounce_timer:close()
    end
    debounce_timer = vim.loop.new_timer()
    debounce_timer:start(300, 0, vim.schedule_wrap(function()
        if debounce_timer then
            debounce_timer:stop()
            debounce_timer:close()
            debounce_timer = nil
        end
        get_diagnostics()
    end))
end

return {
    title = "Diagnostics",
    icon = config["diagnostics"].icon,
    setup = function(_)
        local group = vim.api.nvim_create_augroup("sidebar_nvim_diagnostics_fork", { clear = true })
        vim.api.nvim_create_autocmd("DiagnosticChanged", {
            group = group,
            callback = debounced_update,
        })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = group,
            callback = debounced_update,
        })
        get_diagnostics()
    end,
    update = function(_)
        debounced_update()
    end,
    draw = function(ctx)
        local lines = {}
        local hl = {}

        loclist:draw(ctx, lines, hl)

        if lines == nil or #lines == 0 then
            return "<no diagnostics>"
        else
            return { lines = lines, hl = hl }
        end
    end,
    highlights = {
        groups = {},
        links = {
            SidebarNvimLspDiagnosticsError = "LspDiagnosticsDefaultError",
            SidebarNvimLspDiagnosticsWarning = "LspDiagnosticsDefaultWarning",
            SidebarNvimLspDiagnosticsInfo = "LspDiagnosticsDefaultInformation",
            SidebarNvimLspDiagnosticsHint = "LspDiagnosticsDefaultHint",
            SidebarNvimLspDiagnosticsLineNumber = "SidebarNvimLineNr",
            SidebarNvimLspDiagnosticsColNumber = "SidebarNvimLineNr",
        },
    },
    bindings = {
        ["t"] = function(line)
            loclist:toggle_group_at(line)
        end,
        ["e"] = function(line)
            local location = loclist:get_location_at(line)
            if location == nil then
                return
            end
            vim.cmd("wincmd p")
            vim.cmd("e " .. location.filepath)
            vim.fn.cursor(location.lnum, location.col)
        end,
    },
}
