return {
  'dstein64/nvim-scrollview',
  -- Optional: add configuration options here
  lazy = false,
  config = function()
    require("scrollview").setup({
      current_only = true,   -- show scrollbar only for current window
      signs_on_startup = {'changelist'}
    })
  end,
}

