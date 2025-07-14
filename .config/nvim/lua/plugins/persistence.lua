-- Lua
-- return {
--   "folke/persistence.nvim",
--   event = "BufReadPre", -- this will only start session saving when an actual file was opened
--   opts = {
--     -- add any custom options here
--   }
-- }
return {
  "olimorris/persisted.nvim",
  event = "BufReadPre", -- Ensure the plugin loads only when a buffer has been loaded
  opts = {
    autoload = true,
    -- autosave = true,
    use_git_branch = true,
    telescope = {
    mappings = { -- Mappings for managing sessions in Telescope
      copy_session = "<C-c>",
      change_branch = "<C-b>",
      delete_session = "<C-d>",
    },
    icons = { -- icons displayed in the Telescope picker
      selected = " ",
      dir = "  ",
      branch = " ",
    },
  },
    -- Your config goes here ...
  },
}

-- return {
--   'rmagatti/auto-session',
--   lazy = false,
--
--   ---enables autocomplete for opts
--   ---@module "auto-session"
--   ---@type AutoSession.Config
--   opts = {
--     suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
--     ession_lens = {
--       mappings = {
--         -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
--         delete_session = { "i", "<D-D>" }
--         -- alternate_session = { "i", "<>" },
--         -- copy_session = { "i", "<C-Y>" },
--       },
--     }
--   }
-- }
-- return {
--     "gennaro-tedesco/nvim-possession",
--     dependencies = {
--         "ibhagwan/fzf-lua",
--     },
--     config = true,
--     keys = {
--         { "<leader>sl", function() require("nvim-possession").list() end, desc = "📌list sessions", },
--         { "<leader>sn", function() require("nvim-possession").new() end, desc = "📌create new session", },
--         { "<leader>su", function() require("nvim-possession").update() end, desc = "📌update current session", },
--         { "<leader>sd", function() require("nvim-possession").delete() end, desc = "📌delete selected session"},
--     },
--     defaults = {
--         autosave = true
--     }
-- }
