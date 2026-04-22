return {
  "sidebar-nvim/sidebar.nvim",
  lazy = false,
  config = function()
    local sidebar = require("sidebar-nvim")
    local vuffers_section = require("plugins.sidebar-vuffers")

    sidebar.setup({
      disable_default_keybindings = 0,
      bindings = nil,
      open = false,
      side = "left",
      initial_width = 35,
      hide_statusline = false,
      update_interval = 1000,
      sections = { vuffers_section, "files", "git", "diagnostics" },
      section_separator = {""},
      section_title_separator = {""},
      containers = {
          attach_shell = "/bin/sh", show_all = true, interval = 5000,
      },
      datetime = { format = "%a %b %d, %H:%M", clocks = { { name = "local" } } },
      todos = { ignored_paths = { "~" } },
    })

    local map = vim.keymap.set
    map("n", "\\\\", sidebar.toggle, { desc = "Toggle sidebar" })
    map("n", "<M-b>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 1, cursor_at_content = true })
    end, { desc = "Sidebar: Buffers" })
  end,
}
