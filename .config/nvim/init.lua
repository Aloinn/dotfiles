vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- enables us to require files in our lsp directory
local home_dir = os.getenv("HOME")
package.path = home_dir .. "/.config/nvim/lsp/?.lua;" .. package.path

-- Install `lazy.nvim` plugin manager
require("configs.lazy-bootstrap")

-- Configure and install plugins
require("configs.lazy-plugins")

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- Setting options
require("configs.options")

-- Basic Keymaps
vim.schedule(function()
    require("configs.keymaps")
end)

-- Autocmds
require("configs.autocmds")

-- LSP
require("configs.lsp")
