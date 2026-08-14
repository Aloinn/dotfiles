return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
    dependencies = {
        -- include a picker of your choice, see picker section for more details
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    lazy = leet_arg ~= vim.fn.argv(0, -1),
    opts = {
        arg = "Leet",
        lang = "python3"
    },
    cmd = "Leet",
}
