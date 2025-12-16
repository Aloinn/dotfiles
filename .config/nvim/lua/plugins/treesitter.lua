return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
        pcall(function()
            dofile(vim.g.base46_cache .. "syntax")
            dofile(vim.g.base46_cache .. "treesitter")
        end)
        return {
            ensure_installed = {
                "python",
                "bash",
                "lua",
                "java",
                "ruby",
                "rust",
                "luadoc",
                "markdown",
                "printf",
                "toml",
                "vim",
                "vimdoc",
                "yaml",
            },

            highlight = {
                enable = true,
                use_languagetree = true,
            },

            indent = { enable = true },
        }
    end,

    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}
