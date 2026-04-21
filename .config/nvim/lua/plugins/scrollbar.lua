-- return { 'nvim-mini/mini.map', 
--   event = "VimEnter",
--   mappings = {
--     n = {
-- --            ["<leader>fad"] = require("mini.map").open
--                         -- ["<esc>"] = require("telescope.actions").close,
--                         -- ["<M-s>"] = require("trouble.sources.telescope").open
--         },
--     },
--   config = function(_, opts)
--       local map = vim.keymap.set
--       local mm = require("mini.map")
--       local diagnostic_integration = mm.gen_integration.diagnostic({
--         error = 'DiagnosticFloatingError',
--         warn  = 'DiagnosticFloatingWarn',
--         info  = 'DiagnosticFloatingInfo',
--         hint  = 'DiagnosticFloatingHint',
--       })
--       mm.setup(opts)
--       map("n", "<leader>nnn", mm.open, { desc = "Help" })
--
--   end,
-- }
-- return {
--     "petertriho/nvim-scrollbar",
--     lazy = false,
--     config = function()
--         -- require("hlslens").setup({
--         --    build_position_cb = function(plist, _, _, _)
--         --         require("scrollbar.handlers.search").handler.show(plist.start_pos)
--         --    end,
--         -- })
--         --
--         -- vim.cmd([[
--         --     augroup scrollbar_search_hide
--         --         autocmd!
--         --         autocmd CmdlineLeave : lua require('scrollbar.handlers.search').handler.hide()
--         --     augroup END
--         -- ]])
--         require('gitsigns').setup()
--         require("scrollbar.handlers.gitsigns").setup()
--         require("scrollbar").setup({
--             set_highlights = false,
--             handle = {
--                 color = "#545C62",
--             },
--             marks = {
--                 Cursor = {}
--             }
--         })
--     end
-- }
--  return {
--     'lewis6991/satellite.nvim',
--     lazy = false,
--     config = function()
--       require('satellite').setup {
--           current_only = false,
--           winblend = 30,
--           zindex = 40,
--           excluded_filetypes = {},
--           width = 10,
--           handlers = {
--             cursor = {
--               enable = true,
--               -- Supports any number of symbols
--               symbols = { '⎺', '⎻', '⎼', '⎽' }
--               -- symbols = { '⎻', '⎼' }
--               -- Highlights:
--               -- - SatelliteCursor (default links to NonText
--             },
--             search = {
--               enable = true,
--               -- Highlights:
--               -- - SatelliteSearch (default links to Search)
--               -- - SatelliteSearchCurrent (default links to SearchCurrent)
--             },
--             diagnostic = {
--               enable = true,
--               signs = {'-', '=', '≡'},
--               min_severity = vim.diagnostic.severity.HINT,
--               -- Highlights:
--               -- - SatelliteDiagnosticError (default links to DiagnosticError)
--               -- - SatelliteDiagnosticWarn (default links to DiagnosticWarn)
--               -- - SatelliteDiagnosticInfo (default links to DiagnosticInfo)
--               -- - SatelliteDiagnosticHint (default links to DiagnosticHint)
--             },
--             gitsigns = {
--               enable = true,
--               signs = { -- can only be a single character (multibyte is okay)
--                 add = "│",
--                 change = "│",
--                 delete = "-",
--               },
--               -- Highlights:
--               -- SatelliteGitSignsAdd (default links to GitSignsAdd)
--               -- SatelliteGitSignsChange (default links to GitSignsChange)
--               -- SatelliteGitSignsDelete (default links to GitSignsDelete)
--             },
--             marks = {
--               enable = true,
--               show_builtins = false, -- shows the builtin marks like [ ] < >\\
--               key = 'm'
--               -- Highlights:
--               -- SatelzyliteMark (default links to Normal)
--             },
--             quickfix = {
--               signs = { '-', '=', '≡' },
--               -- Highlights:
--               -- SatelliteQuickfix (default links to WarningMsg)
--             }
--           },
--         }
--   end
-- }

-- return {
--   "wfxr/minimap.vim",
--
--   build = "cargo install --locked code-minimap",
--
--   cmd = {
--     "Minimap",
--     "MinimapClose",
--     "MinimapToggle",
--     "MinimapRefresh",
--     "MinimapUpdateHighlight",
--   },
--
--   keys = {
--     { "\\\\", "<cmd>MinimapToggle<CR>", desc = "Toggle Minimap" },
--     { "<leader>mo", "<cmd>Minimap<CR>", desc = "Open Minimap" },
--     { "<leader>mc", "<cmd>MinimapClose<CR>", desc = "Close Minimap" },
--     { "<leader>mr", "<cmd>MinimapRefresh<CR>", desc = "Refresh Minimap" },
--   },
--
--   init = function()
--     vim.g.minimap_width = 10
--     vim.g.minimap_auto_start = 1
--     vim.g.minimap_auto_start_win_enter = 1
--     vim.g.minimap_highlight_range = 1
--     vim.g.minimap_highlight_search = 1
--     vim.g.minimap_git_colors = 1
--   end,
-- }

return {
  'dstein64/nvim-scrollview',
  -- Optional: add configuration options here
  lazy = false,
  config = function()
    require("scrollview").setup({
      current_only = true,   -- show scrollbar only for current window
      signs_on_startup = {'gitsigns'},
      signs_scrollbar_overlap = "over",
      diagnostics_severities = {vim.diagnostic.severity.ERROR}
    })
    require('scrollview.contrib.gitsigns').setup()
  end,
}


