-- Custom sidebar-nvim section: lists JUnit test methods from all listed
-- java buffers, grouped by file. <CR>/e jumps to the @Test method line.
-- Test discovery is shared with the gutter markers (utils/java_tests.lua).
local Loclist = require("sidebar-nvim.components.loclist")
local java_tests = require("utils.java_tests")

local loclist = Loclist:new({ omit_single_group = false, show_group_count = true })

local function draw(ctx)
    local items = {}

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
            vim.fn.buflisted(buf) == 1
            and vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].filetype == "java"
        then
            local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
            for _, test in ipairs(java_tests.find_tests(buf)) do
                items[#items + 1] = {
                    group = fname,
                    left = {
                        { text = " ▶ ", hl = "JavaTestMark" },
                        { text = test.name, hl = "SidebarNvimNormal" },
                    },
                    data = { buffer = buf, lnum = test.lnum },
                    order = test.lnum,
                }
            end
        end
    end

    local lines, hl = {}, {}
    loclist:set_items(items, { remove_groups = true })
    loclist:draw(ctx, lines, hl)

    if lines == nil or #lines == 0 then
        return "<no tests>"
    end
    return { lines = lines, hl = hl }
end

local function jump(line)
    local location = loclist:get_location_at(line)
    if location == nil then
        -- cursor is on a group (file) header -> collapse/expand it
        loclist:toggle_group_at(line)
        require("sidebar-nvim").update()
        return
    end
    if not vim.api.nvim_buf_is_valid(location.data.buffer) then
        return
    end
    vim.cmd("wincmd p")
    vim.api.nvim_set_current_buf(location.data.buffer)
    vim.api.nvim_win_set_cursor(0, { location.data.lnum + 1, 0 })
    vim.cmd("normal! zz")
end

return {
    title = "Tests",
    icon = "󰙨",
    draw = draw,
    highlights = {
        groups = {},
        links = {},
    },
    bindings = {
        ["e"] = jump,
        ["<CR>"] = jump,
    },
}
