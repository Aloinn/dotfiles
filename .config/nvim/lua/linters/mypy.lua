-- ╭──────────────────────────────────────────────╮
-- │                   Helpers                    │
-- ╰──────────────────────────────────────────────╯

-- path/to/file:line:col: severity: message
local pattern = "([^:]+):(%d+):(%d+):(%d+):(%d+): (%a+): (.*) %[(%a[%a-]+)%]"
local groups = { "file", "lnum", "col", "end_lnum", "end_col", "severity", "message", "code" }
local severities = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    note = vim.diagnostic.severity.HINT,
}

-- ╭──────────────────────────────────────────────╮
-- │                    Args                      │
-- ╰──────────────────────────────────────────────╯

local args = {
    "--show-column-numbers",
    "--show-error-end",
    "--hide-error-context",
    "--no-color-output",
    "--no-error-summary",
    "--no-pretty",
}

-- ╭──────────────────────────────────────────────╮
-- │                   Parser                     │
-- ╰──────────────────────────────────────────────╯

local parser = require("lint.parser").from_pattern(
    pattern,
    groups,
    severities,
    { ["source"] = "mypy" },
    { end_col_offset = 0 }
)

-- ╭──────────────────────────────────────────────╮
-- │                  Config                      │
-- ╰──────────────────────────────────────────────╯

return {
    cmd = "mypy",
    stdin = false,
    stream = "both",
    ignore_exitcode = true,
    args = args,
    parser = parser,
}
