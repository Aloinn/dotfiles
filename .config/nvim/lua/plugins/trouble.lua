return {
    "folke/trouble.nvim",
    opts = {
      modes = {
        preview_floatz = {
          mode = "lsp_references",
          preview = {
            type = "float",
            relative = "editor",
            border = "rounded",
            title = "Preview",
            title_pos = "center",
            position = { 0, -2 },
            size = { width = 0.3, height = 0.3 },
            zindex = 200,
          },
        },
      },
    }, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
        {
            "<M-e>T",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "All trouble",
        },
        {
            "<M-e>t",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer trouble",
        },
        {
              "<M-e>f",
              "<cmd>Trouble telescope_files toggle win.position=float<cr>",
              desc = "Telescope",
        },
        {
              "<M-e>q",
              "<cmd>Trouble qflist toggle<cr>",
              desc = "Quickfix",
        },
    },
    config = function(_, opts)
        require('trouble').setup(opts)
      end,
}
