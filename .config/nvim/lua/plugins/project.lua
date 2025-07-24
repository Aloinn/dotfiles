return
  -- project.nvim [project search + auto cd]
  -- https://github.com/ahmedkhalf/project.nvim
  {
    "zeioth/project.nvim",
    event = "User BaseDefered",
    cmd = "ProjectRoot",
    opts = {
      -- How to find root directory
      patterns = {
        ".git",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
        "Makefile",
        "package.json",
        ".solution",
        ".solution.toml"
      },
      -- Don't list the next projects
      exclude_dirs = {
        "~/",
        -- "/Users/alainlam/"
      },
      silent_chdir = true,
      manual_mode = false,

      -- Don't chdir for certain buffers
      exclude_chdir = {
        filetype = {"", "OverseerList", "alpha"},
        buftype = {"nofile", "terminal"},
      },

      --ignore_lsp = { "lua_ls" },
    },
    config = function(_, opts) require("project_nvim").setup(opts) end,
  }
