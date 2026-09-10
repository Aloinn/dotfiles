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
    -- Resolve symlinks in cwd so session filenames are always based on the
    -- real path (fixes /home -> /local/home mismatch)
    local function resolve_cwd()
      local real_cwd = vim.uv.fs_realpath(vim.fn.getcwd())
      if real_cwd and real_cwd ~= vim.fn.getcwd() then
        vim.cmd.cd(real_cwd)
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

    -- Close sidebar before saving session so it doesn't get baked in
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      callback = function()
        local ok, sidebar = pcall(require, "sidebar-nvim")
        if ok then
          sidebar.close()
        end
      end,
    })

    -- Re-open sidebar after session loads
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedLoadPost",
      callback = function()
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
