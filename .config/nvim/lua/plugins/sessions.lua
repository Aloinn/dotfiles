return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  keys = {
        {"<M-o>", "<cmd>AutoSession search<CR>"}
    },
  opts = {
    session_lens = {
        picker = "telescope",
        picker_opts = {


            }
    },
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    -- log_level = 'debug',
  },
}
-- return {
--
-- }
--
-- return {
--   "Shatur/neovim-session-manager",
--   dependencies = {
--     "nvim-lua/plenary.nvim",
--   },
--   config = function()
--     require("session_manager").setup({
--       autoload_mode = require("session_manager.config").AutoloadMode.CurrentDir,
--     })
--   end,
-- }
