return

  --  which-key.nvim [on-screen keybindings]
  --  https://github.com/folke/which-key.nvim
  {
    "folke/which-key.nvim",
    event = "User BaseDefered",

    opts_extend = { "disable.ft", "disable.bt" },
    opts = {
      preset = "helix", -- "classic", "modern", or "helix"
      icons = {
        group = (vim.g.fallback_icons_enabled and "+") or "",
        rules = false,
        separator = "-",
      },
    },
    plugins = {
      presets = {
        operators = false,
        motions = false,

      }
    },
    config = function(_, opts)
      require("which-key").setup(opts)
      require("base.utils").which_key_register()
    end,
  }
