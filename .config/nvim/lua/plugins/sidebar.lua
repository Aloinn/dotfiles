return {
  "sidebar-nvim/sidebar.nvim",
  lazy = false,
  config = function()
    local sidebar = require("sidebar-nvim")

    local bookmarks_section = require("plugins.sidebar-bookmarks")

    sidebar.setup({
      disable_default_keybindings = 0,
      bindings = nil,
      open = true,
      side = "left",
      initial_width = 35,
      hide_statusline = false,
      update_interval = 1000,
      sections = { "buffers", bookmarks_section, "git", "diagnostics" },
      section_separator = {""},
      section_title_separator = {""},
      containers = {
          attach_shell = "/bin/sh", show_all = true, interval = 5000,
      },
      datetime = { format = "%a %b %d, %H:%M", clocks = { { name = "local" } } },
      buffers = {
          show_numbers = false,
          ignore_not_loaded = true,
          ignore_terminal = true,
      },
      todos = { ignored_paths = { "~" } },
    })

    -- Auto-refresh sidebar on buffer changes
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout" }, {
      callback = function()
        vim.schedule(function()
          local ok, sbn = pcall(require, "sidebar-nvim")
          if ok then sbn.update() end
        end)
      end,
    })

    -- Auto-preview: navigate buffers section and the file opens in the main window
    vim.api.nvim_create_autocmd("CursorMoved", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype ~= "SidebarNvim" then return end
        local ok, lib = pcall(require, "sidebar-nvim.lib")
        if not ok then return end
        local match = lib.find_section_at_cursor({ content_only = true })
        if not match then return end
        local bstate = require("sidebar-nvim.bindings").State
        local e_bindings = bstate.section_bindings["e"]
        local idx = match.section_index
        if e_bindings and e_bindings[idx] then
          local sidebar_win = vim.api.nvim_get_current_win()
          e_bindings[idx](match.section_content_current_line, match.cursor_col)
          vim.api.nvim_set_current_win(sidebar_win)
        end
      end,
    })

    -- Safe buffer delete: patch builtin buffers module directly
    local builtin_buffers = require("sidebar-nvim.builtin.buffers")
    local orig_d = builtin_buffers.bindings["d"]
    builtin_buffers.bindings["d"] = function(line, col)
      local sidebar_win = vim.api.nvim_get_current_win()
      vim.cmd("wincmd p")
      local main_win = vim.api.nvim_get_current_win()
      local main_buf = vim.api.nvim_get_current_buf()
      local alt = nil
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= main_buf and vim.fn.buflisted(b) == 1 then
          alt = b; break
        end
      end
      if alt then
        vim.api.nvim_win_set_buf(main_win, alt)
      else
        vim.cmd("enew")
      end
      vim.api.nvim_set_current_win(sidebar_win)
      orig_d(line, col)
      sidebar.update()
    end
    builtin_buffers.bindings["<CR>"] = builtin_buffers.bindings["e"]
    local orig_e = builtin_buffers.bindings["e"]
    require("sidebar-nvim.bindings").update_section_bindings(1, builtin_buffers.bindings)

    local map = vim.keymap.set
    map("n", "\\\\", sidebar.toggle, { desc = "Toggle sidebar" })
    map("n", "<M-b>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 1, cursor_at_content = true })
    end, { desc = "Sidebar: Buffers" })
  end,
}
