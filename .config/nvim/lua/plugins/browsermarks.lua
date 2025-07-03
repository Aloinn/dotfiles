return {
  'dhruvmanila/browser-bookmarks.nvim',
  dependencies = {
       'nvim-telescope/telescope.nvim',
       'kkharji/sqlite.lua'
  },
  config = function()
    require("browser_bookmarks").setup({
      selected_browser = "buku", -- or "chrome", "firefox", etc
    })

    require("telescope").load_extension("bookmarks")
  end,
  -- }
}
