-- with lazy.nvim
return {
  "LintaoAmons/bookmarks.nvim",
    event = "VimEnter",
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes (major version change)
  tag = "3.2.0",
  dependencies = {
    {"kkharji/sqlite.lua"},
    {"nvim-telescope/telescope.nvim"},  -- currently has only telescopes supported, but PRs for other pickers are welcome 
    {"stevearc/dressing.nvim"}, -- optional: better UI
    -- {"GeorgesAlkhouri/nvim-aider"} -- optional: for Aider integration
  },
    keys = {
        { "\\l", "<cmd>BookmarksGoto<cr>", desc = "List", mode = {"n"} },
        { "\\\\", "<cmd>BookmarksTree<cr>", desc = "Tree", mode = {"n"} },
        { "\\]", "<cmd>BookmarksGotoNext<cr>", desc = "Next", mode = {"n"} },
        { "\\[", "<cmd>BookmarksGotoPrev<cr>", desc = "Prev", mode = {"n"} },
        { "\\b", "<cmd>BookmarksMark<cr>", desc = "Bookmark", mode = {"n"} },
        { "\\g", "<cmd>BookmarksGrep<cr>", desc = "Grep", mode = {"n"} },
        { "\\c", "<cmd>BookmarksCommands<cr>", desc = "Command", mode = {"n"} },
    },
  config = function()
    local opts = {
            signs = {
                mark = {
                    color="#DBBC7F",
                    line_bg = "#323A40"
                }
            },
            treeview = {
                window_split_dimension = 60,
                keymap = {
                   ["v"] = {
                    action = "paste",
                    desc = "Toggle list expansion or go to bookmark location"
                  },
                  ["p"] = {
                    action = "preview",
                    desc = "Toggle list expansion or go to bookmark location"
                  },
                  ["R"] = {
                    action = "reverse",
                    desc = "Toggle list expansion or go to bookmark location"
                  },
                }
            }
        } -- check the "./lua/bookmarks/default-config.lua" file for all the options
    require("bookmarks").setup(opts) -- you must call setup to init sqlite db
  end,
}

-- run :BookmarksInfo to see the running status of the plugin
