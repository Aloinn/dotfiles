-- Lua
return {
  "olimorris/persisted.nvim",
  lazy = false,
  opts = {
    autostart = true,
    autoload = true,
    follow_cwd = true,
    should_save = function()
      -- Don't save session if the only buffer is SidebarNvim
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
          return true
        end
      end
      return false
    end,
  },
  config = function(_, opts)
    -- Resolve the session anchor for the current buffer/cwd:
    -- 1. realpath the cwd (fixes /home -> /local/home symlink mismatch)
    -- 2. walk up to the project root: Brazil workspace root (ws_root_folders
    --    or .bemol dir) or git root. This makes the session key stable no
    --    matter where inside the workspace nvim was launched or what
    --    project.nvim later :cd's to (e.g. jdtls LSP root).
    local function project_root(dir)
      -- Brazil ws markers first: each package is its own git repo, so a
      -- plain .git search from inside a package would stop at the package
      -- instead of the workspace root.
      local ws = vim.fs.find({ ".bemol", "packageInfo" }, { path = dir, upward = true })[1]
      if ws then
        return vim.fs.dirname(ws)
      end
      local git = vim.fs.find({ ".git" }, { path = dir, upward = true })[1]
      if git then
        return vim.fs.dirname(git)
      end
      return dir
    end

    local function resolve_cwd()
      local real_cwd = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
      local root = project_root(real_cwd)
      if root ~= vim.fn.getcwd() then
        vim.cmd.cd(root)
      end
    end
    resolve_cwd()

    local persisted = require("persisted")
    local utils = require("persisted.utils")
    persisted.setup(opts)

    -- Monkey-patch persisted.current() to always resolve symlinks before
    -- generating the session filename. Without this, /home symlink causes
    -- load to look for a file that doesn't match the one save created.
    local orig_current = persisted.current
    persisted.current = function(copts)
      resolve_cwd()
      return orig_current(copts)
    end

    -- Track buffers the user actually visited (displayed in a window).
    -- Buffers created behind the scenes (LSP jdt:// jumps, quickfix tools,
    -- pickers, plugins) never fire BufWinEnter, so they stay unmarked.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function(args)
        if vim.bo[args.buf].buftype == "" and vim.bo[args.buf].filetype ~= "SidebarNvim" then
          vim.b[args.buf].user_visited = true
        end
      end,
    })

    -- Close sidebar before saving session so it doesn't get baked in,
    -- and unlist any buffer the user never visited so mksession skips it.
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      callback = function()
        local ok, sidebar = pcall(require, "sidebar-nvim")
        if ok then
          sidebar.close()
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buflisted and not vim.b[buf].user_visited then
            vim.bo[buf].buflisted = false
          end
        end
      end,
    })

    -- Re-open sidebar after session loads, and grandfather restored
    -- buffers as visited (they were opened by the user in a past session).
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedLoadPost",
      callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buflisted then
            vim.b[buf].user_visited = true
          end
        end
        local ok, sidebar = pcall(require, "sidebar-nvim")
        if ok then
          sidebar.open()
        end
      end,
    })
  end,
}

-- return {
--   "rmagatti/auto-session",
--   lazy = false,
--   opts = {
--     session_lens = {
--         picker = "telescope",
--         picker_opts = {
--             }
--     },
--   },
-- }
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
