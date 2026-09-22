return {
  "sidebar-nvim/sidebar.nvim",
  lazy = false,
  config = function()
    local sidebar = require("sidebar-nvim")

    local bookmarks_section = require("plugins.sidebar-bookmarks")
    -- Forked builtin buffers section with an added buflisted filter
    -- (hides LSP-diagnostic phantom buffers, keeps session buffers)
    local buffers_section = require("plugins.sidebar-buffers")
    -- Custom section: JUnit test methods from open java buffers,
    -- <CR> jumps to the @Test line. Shares discovery with the
    -- gutter "▶" markers (utils/java_tests.lua).
    -- local tests_section = require("plugins.sidebar-tests")
    -- Forked git section: fixes races that transiently blanked the section
    -- (per-cycle results + vim.system + generation counter)
    local git_section = require("plugins.sidebar-git")
    -- Forked builtin diagnostics section: current-buffer only + debounced
    -- (builtin deep-copies ALL buffers' diagnostics on every DiagnosticChanged
    -- -- caused multi-second freezes after JUnit runs)
    local diagnostics_section = require("plugins.sidebar-diagnostics")

    -- "▶" sign beside every @Test method in java buffers
    require("utils.java_tests").setup()

    sidebar.setup({
      disable_default_keybindings = 0,
      bindings = nil,
      side = "left",
      initial_width = 35,
      hide_statusline = false,
      update_interval = 1000,
      sections = { buffers_section, bookmarks_section, git_section, diagnostics_section, tests_section },
      section_separator = {""},
      section_title_separator = {""},
      containers = {
          attach_shell = "/bin/sh", show_all = true, interval = 5000,
      },
      datetime = { format = "%a %b %d, %H:%M", clocks = { { name = "local" } } },
      buffers = {
          show_numbers = false,
          -- Must be false: session restore (badd) creates buffers as
          -- listed-but-not-loaded; true would hide them until visited.
          ignore_not_loaded = false,
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

    -- Auto-preview on highlight: buffers (1), marks (2), git files (3).
    -- Invokes the hovered section's "e" binding in the main window, then
    -- returns focus to the sidebar. Files opened purely by hovering are
    -- kept unlisted (so they don't join the buffer list / session) and are
    -- wiped when the preview moves on; they get promoted to real listed
    -- buffers only when the user deliberately enters them.
    local preview_sections = { [1] = true, [2] = true, [3] = true }
    local preview_bufs = {}

    vim.api.nvim_create_autocmd("CursorMoved", {
      pattern = "*",
      -- nested: :e inside an autocmd only fires FileType/BufReadPost (and
      -- therefore treesitter highlighting) when nested is set
      nested = true,
      callback = function()
        if vim.bo.filetype ~= "SidebarNvim" then return end
        if _updating then return end
        local ok, lib = pcall(require, "sidebar-nvim.lib")
        if not ok then return end
        local match = lib.find_section_at_cursor({ content_only = true })
        if not match or not preview_sections[match.section_index] then return end
        local bstate = require("sidebar-nvim.bindings").State
        local e_bindings = bstate.section_bindings["e"]
        local e = e_bindings and e_bindings[match.section_index]
        if not e then return end

        _updating = true
        local sidebar_win = vim.api.nvim_get_current_win()

        -- Snapshot existing buffers so we can spot preview-created ones
        local existed = {}
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          existed[b] = true
        end

        -- pcall: previewed path may be gone (e.g. git shows a deleted file)
        pcall(e, match.section_content_current_line, match.cursor_col)

        -- If the preview opened a brand-new buffer, keep it out of the
        -- buffer list (and therefore out of the session)
        local cur = vim.api.nvim_get_current_buf()
        if not existed[cur] and vim.bo[cur].buftype == "" then
          vim.bo[cur].buflisted = false
          preview_bufs[cur] = true
          -- Fallback highlight kick in case FileType didn't attach
          if vim.bo[cur].filetype == "" then
            pcall(vim.cmd, "filetype detect")
          end
          if not vim.treesitter.highlighter.active[cur] then
            pcall(vim.treesitter.start, cur)
          end
        end

        -- Wipe stale preview buffers that are no longer displayed
        for b in pairs(preview_bufs) do
          if
            b ~= cur
            and vim.api.nvim_buf_is_valid(b)
            and not vim.bo[b].modified
            and vim.fn.bufwinid(b) == -1
          then
            pcall(vim.api.nvim_buf_delete, b, {})
          end
          if not vim.api.nvim_buf_is_valid(b) then
            preview_bufs[b] = nil
          end
        end

        vim.api.nvim_set_current_win(sidebar_win)
        vim.schedule(function() _updating = false end)
      end,
    })

    -- Promote a preview buffer to a real listed buffer when the user
    -- deliberately lands in it (outside the preview flow)
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function(args)
        if _updating then return end
        if preview_bufs[args.buf] and vim.bo[args.buf].filetype ~= "SidebarNvim" then
          vim.bo[args.buf].buflisted = true
          preview_bufs[args.buf] = nil
        end
      end,
    })

    -- Safe buffer delete: patch the forked buffers module directly
    local builtin_buffers = buffers_section
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
    map("n", "<M-m>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 2, cursor_at_content = true })
    end, { desc = "Sidebar: Git Status" })
    map("n", "\\b", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 1, cursor_at_content = true })
    end, { desc = "Sidebar: Buffers" })
    map("n", "\\g", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 3, cursor_at_content = true })
    end, { desc = "Sidebar: Marks" })
    map("n", "\\m", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 2, cursor_at_content = true })
    end, { desc = "Sidebar: Git Status" })
    map("n", "<M-t>", function()
      if not sidebar.is_open() then sidebar.open() end
      sidebar.focus({ section_index = 5, cursor_at_content = true })
    end, { desc = "Sidebar: Tests" })
  end,
}
