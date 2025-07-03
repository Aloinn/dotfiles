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
    require("telescope").extensions.file_browser.file_browser()
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

-- SEARCH
maps.n["<D-.>"] = { function()
  require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
end, desc = "Search word under cursor" }

utils.set_mappings(maps)
return M
