-- in lua/plugins/treesitter.lua or similar
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "json", -- add this
      "lua",
      "bash",
      "python",
      "markdown",
      -- any other languages you need
    },
  },
}

