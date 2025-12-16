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
                { "gr", group = "[Goto] LSP" },
                { "<leader>f", group = "[F]ind" },
                { "<leader>t", group = "[T]oggle" },
                { "<leader>w", group = "[W]hich Key" },
                { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
            },
        }
    end,
}
