return {
  "hedyhli/outline.nvim",
  lazy = true,
  cmd = { "Outline", "OutlineOpen" },
  keys = { -- Example mapping to toggle outline
    { "\\\\", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    outline_window = {
        auto_jump = true,
        show_symbol_lineno = true,
      show_cursorline = true,
      hide_cursor = true,
    }
  },
}
