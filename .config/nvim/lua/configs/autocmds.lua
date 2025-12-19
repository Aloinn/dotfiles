local autocmd = vim.api.nvim_create_autocmd


local find_or_create_project_bookmark_group = function()
  local project_root = require("project_nvim.project").get_project_root()
  if not project_root then
    return
  end

  local project_name = string.gsub(project_root, "^" .. os.getenv("HOME") .. "/", "")
  local Service = require("bookmarks.domain.service")
  local Repo = require("bookmarks.domain.repo")
  local bookmark_list = nil

  for _, bl in ipairs(Repo.find_lists()) do
    if bl.name == project_name then
      bookmark_list = bl
      break
    end
  end

  if not bookmark_list then
    bookmark_list = Service.create_list(project_name)
  end
  Service.set_active_list(bookmark_list.id)
  require("bookmarks.sign").safe_refresh_signs()
end

vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("BookmarksGroup", {}),
    pattern = { "*" },
    callback = find_or_create_project_bookmark_group,
})


-- user event that loads after UIEnter + only if file buf is there
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
    callback = function(args)
        local file = vim.api.nvim_buf_get_name(args.buf)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

        if not vim.g.ui_entered and args.event == "UIEnter" then
            vim.g.ui_entered = true
        end

        if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
            vim.api.nvim_exec_autocmds("User", { pattern = "FilePost", modeline = false })
            vim.api.nvim_del_augroup_by_name("NvFilePost")

            vim.schedule(function()
                vim.api.nvim_exec_autocmds("FileType", {})

                if vim.g.editorconfig then
                    require("editorconfig").config(args.buf)
                end
            end)
        end
    end,
})

autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({
      higroup = "YankHighlight", -- or "IncSearch"
      timeout = 200,
    })
  end,
})
vim.api.nvim_set_hl(0, "YankHighlight", {
  bg = "#DBBC7F", -- background color
  fg = "#2C3339",       -- keep text color
})

-- DASH
-- if is_available "alpha-nvim" then
local helpers = require("utils.helpers")
local is_available = helpers.is_available
if is_available "alpha-nvim" then
  autocmd({ "User", "BufEnter" }, {
    desc = "Disable status and tablines for alpha",
    callback = function(args)
      local is_filetype_alpha = vim.api.nvim_get_option_value(
        "filetype", { buf = 0 }) == "alpha"
      local is_empty_file = vim.api.nvim_get_option_value(
        "buftype", { buf = 0 }) == "nofile"
      if ((args.event == "User" and args.file == "AlphaReady") or
            (args.event == "BufEnter" and is_filetype_alpha)) and
          not vim.g.before_alpha
      then
        vim.g.before_alpha = {
          showtabline = vim.opt.showtabline:get(),
          laststatus = vim.opt.laststatus:get()
        }
        vim.opt.showtabline, vim.opt.laststatus = 0, 0
      elseif
          vim.g.before_alpha
          and args.event == "BufEnter"
          and not is_empty_file
      then
        vim.opt.laststatus = vim.g.before_alpha.laststatus
        vim.opt.showtabline = vim.g.before_alpha.showtabline
        vim.g.before_alpha = nil
      end
    end,
  })
  autocmd("VimEnter", {
    desc = "Start Alpha only when nvim is opened with no arguments",
    callback = function()
      -- Precalculate conditions.
      local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
      local buf_not_empty = vim.fn.argc() > 0
          or #lines > 1
          or (#lines == 1 and lines[1]:len() > 0)
      local buflist_not_empty = #vim.tbl_filter(
        function(bufnr) return vim.bo[bufnr].buflisted end,
        vim.api.nvim_list_bufs()
      ) > 1
      local buf_not_modifiable = not vim.o.modifiable

      -- Return instead of opening alpha if any of these conditions occur.
      if buf_not_modifiable or buf_not_empty or buflist_not_empty then
        return
      end
      for _, arg in pairs(vim.v.argv) do
        if arg == "-b"
            or arg == "-c"
            or vim.startswith(arg, "+")
            or arg == "-S"
        then
          return
        end
      end

      -- All good? Show alpha.
      require("alpha").start(true, require("alpha").default_config)
      vim.schedule(function() vim.cmd.doautocmd "FileType" end)
    end,
  })
end
