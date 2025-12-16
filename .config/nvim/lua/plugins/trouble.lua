return {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
        {
            "<leader>tT",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "[T]oggle Every [T]rouble",
        },
        {
            "<leader>tt",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "[T]oggle [T]rouble",
        },
    },
}
