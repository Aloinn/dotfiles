  --  Telescope [search] + [search backend] dependency
  --  https://github.com/nvim-telescope/telescope.nvim
  --  https://github.com/nvim-telescope/telescope-fzf-native.nvim
  --  https://github.com/debugloop/telescope-undo.nvim
  --  NOTE: Normally, plugins that depend on Telescope are defined separately.
  --  But its Telescope extension is added in the Telescope 'config' section.i
  -- {
    -- dir = "~/dotfiles/.config/nvim/lua/plugins/pickers.lua",
  -- },
local utils = require("base.utils")
 return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "debugloop/telescope-undo.nvim",
        cmd = "Telescope",
      },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        enabled = vim.fn.executable("make") == 1,
        build = "make",
      },
      {
        "nvim-telescope/telescope-hop.nvim",
      },
    },
    cmd = "Telescope",
    opts = function()
      local get_icon = require("base.utils").get_icon
      local actions = require("telescope.actions")
      local mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<ESC>"] = actions.close,
          ["<C-c>"] = false,
          ["<D-/>"] = require("telescope").extensions.hop.hop,  -- hop.hop_toggle_selection
          ["<M-/>"] = require("telescope").extensions.hop.hop,  -- hop.hop_toggle_selection
          ['<D-d>'] = require('telescope.actions').delete_buffer,
          ['<M-d>'] = require('telescope.actions').delete_buffer
        },
        n = {
          ["q"] = actions.close,
          ["<D-/>"] = require("telescope").extensions.hop.hop,  -- hop.hop_toggle_selection
        },
      }
      return {
        defaults = {
          file_ignore_patterns = {".git/"},
          prompt_prefix = get_icon("PromptPrefix") .. " ",
          selection_caret = get_icon("PromptPrefix") .. " ",
          multi_icon = get_icon("PromptPrefix") .. " ",
          path_display = {
            shorten = 40,
            filename_first = {
              reverse_directories = false
            }
          },
          fname_width = 10,
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.50,
            },
            vertical = {
              prompt_position = "top",
              mirror = true,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 0,
          },
          mappings = mappings,
          border = true,
          borderchars = {
            prompt = { "─", " ", " ", " ", "─", "─", " ", " " },
            results = { "─", " ", " ", " ", "─", "─", " ", " " },
            preview = { "─", " ", " ", "│", "┬", " ", " ", " " }
          }
        },
        extensions = {
          hop ={
            line_hp = "CursorLine"
          },
          file_browser = {
            hidden = { file_browser = true, folder_browser = true }
          },
          undo = {
            use_delta = true,
            side_by_side = true,
            vim_diff_opts = { ctxlen = 0 },
            entry_format = "󰣜 #$ID, $STAT, $TIME",
            layout_strategy = "horizontal",
            layout_config = {
              preview_width = 0.65,
            },
            mappings = {
              i = {
                ["<cr>"] = require("telescope-undo.actions").yank_additions,
                ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
                ["<C-cr>"] = require("telescope-undo.actions").restore,
              },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      -- Here we define the Telescope extension for all plugins.
      -- If you delete a plugin, you can also delete its Telescope extension.
      if utils.is_available("nvim-notify") then telescope.load_extension("notify") end
      if utils.is_available("telescope-fzf-native.nvim") then telescope.load_extension("fzf") end
      if utils.is_available("telescope-undo.nvim") then telescope.load_extension("undo") end
      telescope.load_extension("hop")
      -- if utils.is_available("telescope-hop.nvim") then telescope.load_extension("hop") end
      if utils.is_available("project.nvim") then telescope.load_extension("projects") end
      if utils.is_available("LuaSnip") then telescope.load_extension("luasnip") end
      if utils.is_available("aerial.nvim") then telescope.load_extension("aerial") end
      if utils.is_available("nvim-neoclip.lua") then
        telescope.load_extension("neoclip")
        telescope.load_extension("macroscope")
      end
    end,
  }

