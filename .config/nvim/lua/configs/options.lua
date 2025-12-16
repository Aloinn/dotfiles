local opt = vim.opt
local o = vim.o
local g = vim.g

-- ╭──────────────────────────────────────────────╮
-- │                  General                     │
-- ╰──────────────────────────────────────────────╯

o.winborder = "rounded"
o.laststatus = 3
o.showmode = false
o.swapfile = false

o.clipboard = "unnamedplus"
o.cursorline = true
o.cursorlineopt = "number"

opt.shortmess:append("sI")

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.timeoutlen = 400
o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append("<>[]hl")

opt.colorcolumn = "100000"

-- ╭──────────────────────────────────────────────╮
-- │                 Indenting                    │
-- ╰──────────────────────────────────────────────╯

o.expandtab = true
o.shiftwidth = 4
o.smartindent = true
o.tabstop = 4
o.softtabstop = 4

opt.fillchars = { eob = " " }
o.ignorecase = true
o.smartcase = true

-- ╭──────────────────────────────────────────────╮
-- │                    Mouse                     │
-- ╰──────────────────────────────────────────────╯

o.mouse = "a"
o.mousescroll = "ver:1,hor:6"

-- ╭──────────────────────────────────────────────╮
-- │                   Numbers                    │
-- ╰──────────────────────────────────────────────╯

o.number = true
o.numberwidth = 2
o.ruler = false
opt.relativenumber = true

-- ╭──────────────────────────────────────────────╮
-- │                 Providers                    │
-- ╰──────────────────────────────────────────────╯

g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- ╭──────────────────────────────────────────────╮
-- │                  Spelling                    │
-- ╰──────────────────────────────────────────────╯

opt.spell = true
opt.spelllang = "en_us"
opt.spelloptions = "camel"

-- ╭──────────────────────────────────────────────╮
-- │                   Files                      │
-- ╰──────────────────────────────────────────────╯

vim.filetype.add({
  extension = {
    properties = "dosini",
  },
})
