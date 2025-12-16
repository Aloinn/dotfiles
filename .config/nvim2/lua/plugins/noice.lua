return {
  --  Noice.nvim [better cmd/search line]
  --  https://github.com/folke/noice.nvim
  --  We use it for:
  --  * cmdline: Display treesitter for :
  --  * search: Display a magnifier instead of /
  --
  --  We don't use it for:
  --  * LSP status: We use a heirline component for this.
  --  * Search results: We use a heirline component for this.
  {
    "folke/noice.nvim",
    event = "User BaseDefered",
    opts = function()
      local enable_conceal = false          -- Hide command text if true
      return {
        presets = { bottom_search = true }, -- The kind of popup used for /
        cmdline = {
          view = "cmdline",                 -- The kind of popup used for :
          format = {
            cmdline = { conceal = enable_conceal },
            search_down = { conceal = enable_conceal },
            search_up = { conceal = enable_conceal },
            filter = { conceal = enable_conceal },
            lua = { conceal = enable_conceal },
            help = { conceal = enable_conceal },
            input = { conceal = enable_conceal },
          }
        },

        -- Disable every other noice feature
        messages = { enabled = false },
        lsp = {
          hover = { enabled = false },
          signature = { enabled = false },
          progress = { enabled = false },
          message = { enabled = false },
          smart_move = { enabled = false },
        },
      }
    end
  },
}
