return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  keys = {
        {"<M-f>S", "<cmd>AutoSession search<CR>"}
    },
  opts = {
    session_lens = {
        picker = "telescope"
    },
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    -- log_level = 'debug',
  },
}
