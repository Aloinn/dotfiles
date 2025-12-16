local helpers = require('utils.helpers')

-- ╭──────────────────────────────────────────────╮
-- │                    Args                      │
-- ╰──────────────────────────────────────────────╯

local args = {
    '--format',
    'json',
    '--force-exclusion',
    '--server',
    '--stdin',
    helpers.get_file_name(),
}

-- ╭──────────────────────────────────────────────╮
-- │                  Parser                      │
-- ╰──────────────────────────────────────────────╯

local parser = function(output)
    local severity_map = {
        ['fatal'] = vim.diagnostic.severity.ERROR,
        ['error'] = vim.diagnostic.severity.ERROR,
        ['warning'] = vim.diagnostic.severity.WARN,
        ['convention'] = vim.diagnostic.severity.HINT,
        ['refactor'] = vim.diagnostic.severity.INFO,
        ['info'] = vim.diagnostic.severity.INFO,
    }
    local diagnostics = {}
    local decoded = vim.json.decode(output)

    if not decoded.files[1] then
        return diagnostics
    end

    local offences = decoded.files[1].offenses

    for _, off in pairs(offences) do
        local start_line = off.location.start_line - 1
        local start_col = off.location.start_column - 1

        -- If the offense spans multiple lines, limit it to the first line
        local is_multiline = off.location.last_line ~= off.location.start_line
        local end_line = start_line
        local end_col = is_multiline and -1 or off.location.last_column

        table.insert(diagnostics, {
            source = 'rubocop',
            lnum = start_line,
            col = start_col,
            end_lnum = end_line,
            end_col = end_col,
            severity = severity_map[off.severity],
            message = off.message,
            code = off.cop_name
        })
    end
    return diagnostics
end

-- ╭──────────────────────────────────────────────╮
-- │                  Config                      │
-- ╰──────────────────────────────────────────────╯

return {
    cmd = 'rubocop',
    stdin = true,
    args = args,
    ignore_exitcode = true,
    parser = parser
}
