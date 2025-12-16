-- find defaults linter configs here: https://github.com/mfussenegger/nvim-lint/tree/master/lua/lint/linters
--
-- I like to copy the default into it's own file in lua/linters so that I can have full
-- control over the behavior
return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        local linters = require("lint").linters

        -- enable linters here
        lint.linters_by_ft = {
            python = {
                "mypy",
                "ruff",
            },
            ruby = { "rubocop" },
        }

        -- add linter configuration here
        linters.mypy = require("linters.mypy")
        linters.ruff = require("linters.ruff")
        linters.rubocop = require("linters.rubocop")

        -- linting autocommand
        vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
            callback = function()
                lint.try_lint()
            end,
        })
    end,
}
