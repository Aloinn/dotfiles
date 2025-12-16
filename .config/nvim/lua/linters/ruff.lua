local helpers = require("utils.helpers")

-- ╭──────────────────────────────────────────────╮
-- │                     Args                     │
-- ╰──────────────────────────────────────────────╯

local args = {
    "check",
    "--force-exclude",
    "--quiet",
    "--stdin-filename",
    helpers.get_file_name,
    "--no-fix",
    "--output-format",
    "json",
    "-",
}

-- ╭──────────────────────────────────────────────╮
-- │                   Parser                     │
-- ╰──────────────────────────────────────────────╯

local parser = function(output)
    local error = vim.diagnostic.severity.ERROR
    local severities = {
        ["F821"] = error, -- undefined name `name`
        ["E902"] = error, -- `IOError`
        ["E999"] = error, -- `SyntaxError`
    }
    local diagnostics = {}
    local ok, results = pcall(vim.json.decode, output)
    if not ok then
        return diagnostics
    end
    for _, result in ipairs(results or {}) do
        local diagnostic = {
            message = result.message,
            col = result.location.column - 1,
            end_col = result.end_location.column - 1,
            lnum = result.location.row - 1,
            end_lnum = result.end_location.row - 1,
            code = result.code,
            severity = severities[result.code] or vim.diagnostic.severity.WARN,
            source = "ruff",
        }
        table.insert(diagnostics, diagnostic)
    end
    return diagnostics
end

-- ╭──────────────────────────────────────────────╮
-- │                  Config                      │
-- ╰──────────────────────────────────────────────╯

return {
    cmd = "ruff",
    stdin = true,
    args = args,
    ignore_exitcode = true,
    stream = "stdout",
    parser = parser,
}
