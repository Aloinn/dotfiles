return {
  "sidebar-nvim/sidebar.nvim",
  lazy = false,
  config = function()
    local sidebar = require("sidebar-nvim")
    sidebar.setup({
      disable_default_keybindings = 0,
      bindings = nil,
      open = false,
      side = "left",
      initial_width = 35,
      hide_statusline = false,
      update_interval = 1000,
      sections = { "datetime", "files", "buffers", "git", "diagnostics" },
      section_separator = {""},
      section_title_separator = {""},
      containers = {
          attach_shell = "/bin/sh", show_all = true, interval = 5000,
      },
      datetime = { format = "%a %b %d, %H:%M", clocks = { { name = "local" } } },
      todos = { ignored_paths = { "~" } },
      -- Add your configuration options here.
      -- Example: open the sidebar automatically
      -- Other options can be found in the official documentation
    })
    local map = vim.keymap.set
    -- map("n", "\\\\", sidebar.toggle, { desc = "Help" })

    map("n", "\\\\", sidebar.toggle, { desc = "Help" })
  end,
}

-- return {
--   "Hajime-Suzuki/vuffers.nvim",
--   dependencies = { "nvim-tree/nvim-web-devicons" },
--   lazy = false,
--   config = function()
--     local vuf = require("vuffers")
--     local map = vim.keymap.set
--
--     vuf.setup({
--       debug = {
--         enabled = true,
--         level = "error", -- "error" | "warn" | "info" | "debug" | "trace"
--       },
--       exclude = {
--         -- do not show them on the vuffers list
--         filenames = { "term://" },
--         filetypes = { "lazygit", "NvimTree", "qf" },
--       },
--       handlers = {
--         -- when deleting a buffer via vuffers list (by default triggered by "d" key)
--         on_delete_buffer = function(bufnr)
--           vim.api.nvim_command(":bwipeout " .. bufnr)
--         end,
--       },
--       keymaps = {
--         -- if false, no bindings will be provided at all
--         -- thus you will have to bind on your own
--         use_default = true,
--         -- key maps on the vuffers list
--         -- - may map multiple keys for the same action
--         --    open = { "<CR>", "<C-l>" }
--         -- - disable a specific binding using "false"
--         --    open = false
--         view = {
--           open = "<CR>",
--           delete = "d",
--           pin = "p",
--           unpin = "P",
--           rename = "r",
--           reset_custom_display_name = "R",
--           reset_custom_display_names = "<leader>R",
--           move_up = "U",
--           move_down = "D",
--           move_to = "i",
--         },
--       },
--       sort = {
--         type = "none", -- "none" | "filename"
--         direction = "asc", -- "asc" | "desc"
--       },
--       view = {
--         modified_icon = "󰛿", -- when a buffer is modified, this icon will be shown
--         pinned_icon = "󰐾",
--         show_file_extension = false,
--         window = {
--           auto_resize= false,
--           width = 35,
--           focus_on_open = false,
--         },
--       },
--     })
--
--     map("n", "\\\\", vuf.toggle, { desc = "open" })
--
--   end,
-- }
