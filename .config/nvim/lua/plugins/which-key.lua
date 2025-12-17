return {
    "folke/which-key.nvim",
    event = "VimEnter",
    cmd = "WhichKey",
    opts = function()
        dofile(vim.g.base46_cache .. "whichkey")
        return {
            preset = "helix",
            icons = {
                -- These ensure that which-key uses my nerd font
                mappings = true,
                keys = {},
            },

            -- Document existing key chains
            spec = {
                { "<M-.>", group = "LSP" },
                { "<M-e>", group = "Toggle" },
                { "<M-g>", group = "Git Hunks", mode = { "n", "v" } },
                { "?", group = "Which keys" }
            },
        }
    end,
}
