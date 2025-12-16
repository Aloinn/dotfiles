return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        notify_on_error = true,
        -- format_on_save = {
        --     timeout_ms = 500,
        --     lsp_format = "fallback",
        -- },
        formatters_by_ft = {
            lua = { "stylua" },
            bash = { "shfmt" },
            json = { "jq" },
            python = {
                "ruff_format",
                "ruff_organize_imports",
            },
            rust = { "rustfmt" },
            java = { "google-java-format" },
            ruby = { "rubocop" },
        },
    },
}
