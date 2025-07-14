local M = {}
local utils = require("base.utils")
local maps = require("base.utils").get_mappings_template()

-- CYCLE FIND
local my_find_files
my_find_files = function(opts, state)
  opts = opts or {}
  state = vim.F.if_nil(state, 0)
  opts.attach_mappings = function(_, map)
    telescope_switch = function(prompt_bufnr) -- <C-h> to toggle modes
      local prompt = require("telescope.actions.state").get_current_line()
      require("telescope.actions").close(prompt_bufnr)
      my_find_files({ default_text = prompt }, (1 + state) % 3)
    end
    map({ "n", "i" }, "<D-p>", telescope_switch)
    map({ "n", "i" }, "<M-p>", telescope_switch)
    return true
  end

  if state == 0 then
    opts.prompt_title = "Find Files"
    require("telescope.builtin").find_files(opts)
  elseif state == 1 then
    opts.state = true
    opts.hidden = true
    opts.prompt_title = "Find Files <ALL>"
    require("telescope.builtin").find_files(opts)
  elseif state == 2 then
    opts.prompt_title = "Manage files"
    require("telescope").load_extension("persisted")
    -- require("telescope").extensions.file_browser.file_browser()
  end
end

maps.n["<D-p>"] = {
  my_find_files,
  desc = "Find files"
}

-- STANDARDS
maps.n["<D-s>"] = {
  "<cmd>:w"
}


-- DELETE
maps.n["D"] = {'"_dd', desc = "Delete line",   noremap = true }
maps.x["d"] = {'"_d', desc = "Delete selection", noremap = true}

-- CLIPBOARD
maps.n["<D-c>"] = { '"+y<esc>', desc = "Copy to cliboard" }
maps.x["<A-c>"] = { '"+y<esc>', desc = "Copy to cliboard" }
maps.n["<D-x>"] = { '"+y<esc>dd', desc = "Copy to clipboard and delete line" }
maps.x["<D-x>"] = { '"+y<esc>dd', desc = "Copy to clipboard and delete line" }
maps.n["<D-v>"] = { '"+p<esc>', desc = "Paste from clipboard" }
maps.x["<D-c>"] = {
  "y"
}

-- GIT
maps.n["<D-g>"] = {"<cmd>LazyGit<cr>"}

-- SESSION
maps.n["<D-S>"] = {"<cmd>Telescope persisted<cr>"}
-- maps.n["<leader>S"] = icons.S
maps.n["<leader>Sl"] = {
  "<cmd>SessionManager! load_last_session<cr>",
  desc = "Load last session",
}
maps.n["<leader>Ss"] = {
  "<cmd>SessionManager! save_current_session<cr>",
  desc = "Save this session",
}
maps.n["<leader>Sd"] =
{ "<cmd>SessionManager! delete_session<cr>", desc = "Delete session" }
maps.n["<leader>Sf"] =
{ "<cmd>SessionManager! load_session<cr>", desc = "Search sessions" }
maps.n["<leader>S."] = {
  "<cmd>SessionManager! load_current_dir_session<cr>",
  desc = "Load current directory session",
}
-- if is_available("resession.nvim") then
--   maps.n["<leader>S"] = icons.S
--   maps.n["<leader>Sl"] = {
--     function() require("resession").load "Last Session" end,
--     desc = "Load last session",
--   }
--   maps.n["<leader>Ss"] =
--   { function() require("resession").save() end, desc = "Save this session" }
--   maps.n["<leader>St"] = {
--     function() require("resession").save_tab() end,
--     desc = "Save this tab's session",
--   }
--   maps.n["<leader>Sd"] =
--   { function() require("resession").delete() end, desc = "Delete a session" }
--   maps.n["<leader>Sf"] =
--   { function() require("resession").load() end, desc = "Load a session" }
--   maps.n["<leader>S."] = {
--     function()
--       require("resession").load(vim.fn.getcwd(), { dir = "dirsession" })
--     end,
--     desc = "Load current directory session",
--   }
-- end

-- LSP
lsp_cycle = function(opts, state)
  opts = opts or {}
  state = vim.F.if_nil(state, 0)
  opts.attach_mappings = function(_, map)
    telescope_switch = function(prompt_bufnr) -- <C-h> to toggle modes
      local prompt = require("telescope.actions.state").get_current_line()
      require("telescope.actions").close(prompt_bufnr)
      lsp_cycle({ default_text = prompt }, (1 + state) % 3)
    end
    map({ "n", "i" }, "<D-.>", telescope_switch)
    map({ "n", "i" }, "<M-.>", telescope_switch)
    return true
  end

  if state == 0 then
    require("telescope.builtin").lsp_definitions()
  elseif state == 1 then
    require("telescope.builtin").lsp_references()
  elseif state == 2 then
    opts.prompt_title = "Manage files"
    -- require("telescope").extensions.file_browser.file_browser()
  end
end
-- maps.n["<D-.>"] = { lsp_cycle, desc = "Go to defintion"}

maps.n["<D-.>d"] = { require("telescope.builtin").lsp_type_definitions, desc = "Go to Definition" }
maps.n["<D-.>i"] = { require("telescope.builtin").lsp_implementations,  desc = "Go to Implementation" }
maps.n["<D-.>."] = { require("telescope.builtin").lsp_type_definitions, desc = "Go to Type Definition" }
-- maps.n["<D-.>D"] = { vim.lsp.buf.declaration, desc = "Go to Declaration" }
maps.n["<D-.>r"] = { require("telescope.builtin").lsp_references, desc = "Find References" }
maps.n["<D-.>y"] = { require("telescope.builtin").lsp_references, desc = "Rename Symbol" }

--
-- maps.n["<D-.>"] = { function()
-- maps.n["<D-.>"] = { 
--         map("grj", vim.lsp.buf.rename, "[R]e[n]ame")
--         map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
--         map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
--         map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
--         map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
--         map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
--         map("grO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
--         map("grW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
--         map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
--
--
--   require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
-- end, desc = "Search word under cursor" }
--
-- -- maps.n["<D-.>"] = { require("telescope.builtin").lsp_references, desc = "Go to defintion"}

utils.set_mappings(maps)
return M
