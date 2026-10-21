return {
  {
    url = "ssh://git.amazon.com:2222/pkg/Vim-code-browse",
    branch = "mainline",
    enabled = require("utils.host").is_amazon_host,
    dependencies = "tpope/vim-fugitive",
    event = "VeryLazy",
  },
}
