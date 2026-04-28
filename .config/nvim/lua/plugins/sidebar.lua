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
    local _updating = false
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout" }, {
      callback = function()
        if _updating then return end
        vim.schedule(function()
          local ok, sbn = pcall(require, "sidebar-nvim")
          if ok then sbn.update() end
        end)
      end,
    })

    -- Auto-preview: only for buffers section (index 1)
    vim.api.nvim_create_autocmd("CursorMoved", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype ~= "SidebarNvim" then return end
        if _updating then return end
        local ok, lib = pcall(require, "sidebar-nvim.lib")
        if not ok then return end
        local match = lib.find_section_at_cursor({ content_only = true })
        if not match or match.section_index ~= 1 then return end
        local bstate = require("sidebar-nvim.bindings").State
        local e_bindings = bstate.section_bindings["e"]
        if e_bindings and e_bindings[1] then
          _updating = true
          local sidebar_win = vim.api.nvim_get_current_win()
          e_bindings[1](match.section_content_current_line, match.cursor_col)
          vim.api.nvim_set_current_win(sidebar_win)
          vim.schedule(function() _updating = false end)
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

    -- Patch git section to show only filenames (not full paths)
    require("sidebar-nvim.utils").shortest_path = function(path)
      return vim.fn.fnamemodify(path, ":t")
    end
    --
    -- -- Hide Unmerged and Untracked groups from git section
    -- local git_mod = require("sidebar-nvim.builtin.git")
    -- local orig_draw = git_mod.draw
    -- git_mod.draw = function(ctx)
    --   local result = orig_draw(ctx)
    --   local lines, hl = {}, {}
    --   local skip = false
    --   local old_to_new = {}
    --   for i, line in ipairs(result.lines) do
    --     if line:match("Unmerged") or line:match("Untracked") then
    --       skip = true
    --     elseif line:match("Staged") or line:match("Unstaged") then
    --       skip = false
    --     end
    --     if not skip then
    --       table.insert(lines, line)
    --       old_to_new[i - 1] = #lines - 1
    --     end
    --   end
    --   for _, h in ipairs(result.hl or {}) do
    --     local new_idx = old_to_new[h[2]]
    --     if new_idx then
    --       table.insert(hl, { h[1], new_idx, h[3], h[4] })
    --     end
    --   end
    --   if #lines == 0 then lines = { "<no changes>" } end
    --   return { lines = lines, hl = hl }
    -- end
    --
    local map = vim.keymap.set
    map("n", "\\\\", sidebar.toggle, { desc = "Toggle sidebar" })
    map("n", "<M-b>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 1, cursor_at_content = true })
    end, { desc = "Sidebar: Buffers" })
    map("n", "<M-g>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 3, cursor_at_content = true })
    end, { desc = "Sidebar: Git Status" })
  end,
}
