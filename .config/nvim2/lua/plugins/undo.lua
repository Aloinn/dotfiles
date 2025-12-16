return
  --  highlight-undo
  --  https://github.com/tzachar/highlight-undo.nvim
  --  This plugin only flases on undo/redo.
  --  But we also have a autocmd to flash on yank.
  {
    "tzachar/highlight-undo.nvim",
    event = "User BaseDefered",
    opts = {
      duration = 150,
      hlgroup = "IncSearch",
    },
    config = function(_, opts)
      require("highlight-undo").setup(opts)

      -- Also flash on yank.
      vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight yanked text",
        pattern = "*",
        callback = function()
          (vim.hl or vim.highlight).on_yank()
        end,
      })
    end,
  }
