-- Locate JUnit test methods in java buffers via treesitter.
-- Used by:
--   * gutter markers: a "▶" sign beside every @Test method (setup() below)
--   * the sidebar Tests section (lua/plugins/sidebar-tests.lua)
local M = {}

local ns = vim.api.nvim_create_namespace("java-test-marks")

local TEST_ANNOTATIONS = {
    Test = true, -- JUnit 4 + 5
    ParameterizedTest = true,
    RepeatedTest = true,
    TestFactory = true,
    TestTemplate = true,
}

local QUERY = [[
  (method_declaration
    (modifiers
      [
        (marker_annotation name: (identifier) @annotation)
        (annotation name: (identifier) @annotation)
      ])
    name: (identifier) @name) @method
]]

-- bufnr -> { tick = changedtick, tests = {...} } so the 1s sidebar
-- refresh doesn't re-parse unchanged buffers
local cache = {}

--- Returns sorted { name, lnum (0-based), bufnr } for every test method.
function M.find_tests(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return {}
    end

    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    local cached = cache[bufnr]
    if cached and cached.tick == tick then
        return cached.tests
    end

    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, "java")
    if not ok_parser or not parser then
        return {}
    end
    local ok_query, query = pcall(vim.treesitter.query.parse, "java", QUERY)
    if not ok_query then
        return {}
    end
    local tree = parser:parse()[1]
    if not tree then
        return {}
    end

    local tests, seen = {}, {}
    for _, match in query:iter_matches(tree:root(), bufnr, 0, -1) do
        local annot_text, name_node, method_node
        for id, nodes in pairs(match) do
            -- nvim 0.11 yields a list of nodes per capture id; older
            -- versions yield a single node
            local node = type(nodes) == "table" and nodes[#nodes] or nodes
            local cap = query.captures[id]
            if cap == "annotation" then
                annot_text = vim.treesitter.get_node_text(node, bufnr)
            elseif cap == "name" then
                name_node = node
            elseif cap == "method" then
                method_node = node
            end
        end
        if annot_text and TEST_ANNOTATIONS[annot_text] and method_node and name_node then
            local id = method_node:id()
            if not seen[id] then
                seen[id] = true
                local lnum = method_node:range()
                tests[#tests + 1] = {
                    name = vim.treesitter.get_node_text(name_node, bufnr),
                    lnum = lnum,
                    bufnr = bufnr,
                }
            end
        end
    end
    table.sort(tests, function(a, b)
        return a.lnum < b.lnum
    end)

    cache[bufnr] = { tick = tick, tests = tests }
    return tests
end

--- Place a "▶" sign beside every test method in the buffer.
function M.update_marks(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    for _, test in ipairs(M.find_tests(bufnr)) do
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, test.lnum, 0, {
            sign_text = "▶",
            sign_hl_group = "JavaTestMark",
            priority = 5, -- below gitsigns/diagnostics so those still win the column
        })
    end
end

function M.setup()
    vim.api.nvim_set_hl(0, "JavaTestMark", { default = true, link = "DiagnosticOk" })

    local aug = vim.api.nvim_create_augroup("java-test-marks", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = aug,
        pattern = "java",
        callback = function(args)
            local buf = args.buf
            if vim.b[buf].java_test_marks_attached then
                return
            end
            vim.b[buf].java_test_marks_attached = true

            vim.schedule(function()
                M.update_marks(buf)
            end)
            vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufWritePost" }, {
                group = aug,
                buffer = buf,
                callback = function()
                    vim.schedule(function()
                        M.update_marks(buf)
                    end)
                end,
            })
        end,
    })

    vim.api.nvim_create_autocmd("BufWipeout", {
        group = aug,
        callback = function(args)
            cache[args.buf] = nil
        end,
    })
end

return M
