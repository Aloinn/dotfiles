return
  {
  --  alpha-nvim [greeter]
  --  https://github.com/goolord/alpha-nvim
  {
    "goolord/alpha-nvim",
    cmd = "Alpha",
    -- setup header and buttonts
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {
[[/\\\\\    /\\\\\    /\\ /\\   ]],
[[/\\   /\\ /\\   /\\ /\    /\\ ]],
[[/\\    /\\/\\    /\\/\     /\\]],
[[/\\    /\\/\\    /\\/\\\ /\   ]],
[[/\\    /\\/\\    /\\/\     /\\]],
[[/\\   /\\ /\\   /\\ /\      /\]],
[[/\\\\\    /\\\\\    /\\\\ /\\ ]]
        }


      local get_icon = require("base.utils").get_icon

      dashboard.section.header.opts.hl = "DashboardHeader"
      vim.cmd("highlight DashboardHeader guifg=#F7778F")

      -- If yazi is not installed, don't show the button.
      local is_yazi_installed = vim.fn.executable("ya") == 1
      local yazi_button = dashboard.button("r", get_icon("GreeterYazi") .. " Yazi", "<cmd>Yazi<CR>")
      if not is_yazi_installed then yazi_button = nil end

      -- Buttons
      dashboard.section.buttons.val = {
        -- dashboard.button("n",
          -- get_icon("GreeterNew") .. " New",
          -- "<cmd>ene<CR>"),
        -- dashboard.button("e",
          -- get_icon("GreeterRecent") .. " Recent  ",
          -- "<cmd>Telescope oldfiles<CR>"),
        -- yazi_button,
        dashboard.button("s",
          get_icon("GreeterSessions") .. " Sessions",
          "<cmd>SessionManager! load_session<CR>"
        ),
        dashboard.button("p",
          get_icon("GreeterProjects") .. " Projects",
          "<cmd>Telescope projects<CR>"),
        dashboard.button("b",
          get_icon("GreeterBookmarks") .. " Bookmarks",
          "<cmd>Telescope bookmarks<CR>"),  
        dashboard.button("t", 
          get_icon("GreeterTerminal") .. " Terminal", "<cmd>exit<CR>"),
        -- dashboard.button("", ""),
        dashboard.button("q", "   ", "<cmd>exit<CR>"),
      }

      -- Vertical margins
      dashboard.config.layout[1].val =
          vim.fn.max { 2, vim.fn.floor(vim.fn.winheight(0) * 0.10) } -- Above header
      dashboard.config.layout[3].val =
          vim.fn.max { 2, vim.fn.floor(vim.fn.winheight(0) * 0.10) } -- Above buttons

      -- Disable autocmd and return
      dashboard.config.opts.noautocmd = true
      return dashboard
    end,
    config = function(_, opts)
      -- Footer
      require("alpha").setup(opts.config)
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        desc = "Add Alpha dashboard footer",
        once = true,
        callback = function()
          local  footer_icon = require("base.utils").get_icon("GreeterPlug")
          local stats = require("lazy").stats()
          stats.real_cputime = not is_windows
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          -- opts.section.footer.val = {
          --   " ",
          --   " ",
          --   " ",
          --   "Loaded " .. stats.loaded .. " plugins " .. footer_icon .. " in " .. ms .. "ms",
          --   ".............................",
          -- }
          opts.section.footer.opts.hl = "DashboardFooter"
          vim.cmd("highlight DashboardFooter guifg=#D29B68")
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },


  --  mini.indentscope [guides]
  --  https://github.com/echasnovski/mini.indentscope
  {
    "echasnovski/mini.indentscope",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      draw = { delay = 0, animation = function() return 0 end },
      options = { border = "top", try_as_border = true },
      symbol = "▏",
    },
    config = function(_, opts)
      require("mini.indentscope").setup(opts)

      -- Disable for certain filetypes
      vim.api.nvim_create_autocmd({ "FileType" }, {
        desc = "Disable indentscope for certain filetypes",
        callback = function()
          local ignored_filetypes = {
            "aerial",
            "dashboard",
            "help",
            "lazy",
            "leetcode.nvim",
            "mason",
            "neo-tree",
            "NvimTree",
            "neogitstatus",
            "notify",
            "startify",
            "toggleterm",
            "Trouble",
            "calltree",
            "coverage"
          }
          if vim.tbl_contains(ignored_filetypes, vim.bo.filetype) then
            vim.b.miniindentscope_disable = true
          end
        end,
      })
    end
  },

}
