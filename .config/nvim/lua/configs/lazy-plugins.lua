local orig_keymap_set = vim.keymap.set

vim.keymap.set = function(mode, lhs, rhs, opts)
  -- call original mapping
  orig_keymap_set(mode, lhs, rhs, opts)

  -- duplicate <D-*> mappings as <M-*>
  if type(lhs) == "string" and lhs:match("^<M%-") then
    local alt_lhs = lhs:gsub("^<M%-", "<D-")
    orig_keymap_set(mode, alt_lhs, rhs, opts)
  end
end

require("lazy").setup({
    require("plugins.lsppreview"),
    require("plugins.outline"),
    require("plugins.illuminate"),
    require("plugins.indent"),
    require("plugins.bookmarks"),
    require("plugins.projects"),
    require("plugins.dashboard"),
    require("plugins.sessions"),
    require("plugins.plenary"),
    require("plugins.base46"),
    require("plugins.ui"),
    require("plugins.volt"),
    require("plugins.menu"),
    require("plugins.minty"),
    require("plugins.nvim-web-devicons"),
    require("plugins.indent-blankline"),
    require("plugins.nvim-tree"),
    require("plugins.conform"),
    require("plugins.which-key"),
    require("plugins.gitsigns"),
    require("plugins.nvim-cmp"),
    require("plugins.telescope"),
    require("plugins.treesitter"),
    require("plugins.nvim-lint"),
    require("plugins.vim-tmux-navigator"),
    -- require("plugins.oil"),
    require("plugins.minifiles"),
    require("plugins.hop"),
    require("plugins.trouble"),
    require("plugins.highlight"),
}, {
    defaults = { lazy = true },
    install = { colorscheme = { "nvchad" } },
    ui = {
        icons = {
            ft = "",
            lazy = "󰂠 ",
            loaded = "",
            not_loaded = "",
        },
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "2html_plugin",
                "tohtml",
                "getscript",
                "getscriptPlugin",
                "gzip",
                "logipat",
                "netrw",
                "netrwPlugin",
                "netrwSettings",
                "netrwFileHandlers",
                "matchit",
                "tar",
                "tarPlugin",
                "rrhelper",
                "spellfile_plugin",
                "vimball",
                "vimballPlugin",
                "zip",
                "zipPlugin",
                "tutor",
                "rplugin",
                "syntax",
                "synmenu",
                "optwin",
                "compiler",
                "bugreport",
                "ftplugin",
            },
        },
    },
})
