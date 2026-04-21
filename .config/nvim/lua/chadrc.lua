---@type ChadrcConfig
local M = {
    ui = {
        tabufline = { enabled = false},
        statusline = {
            theme = "vscode_colored",
            -- order = { "mode", "%F", "git", "%=", "lsp_msg", "%=", "lsp", "cwd" },
        }
    },
    base46 = {
        theme = "everforest",
    },
    nvdash = {
     load_on_startup = false,

     header = {
[[/\\\\\    /\\\\\    /\\ /\\   ]],
[[/\\   /\\ /\\   /\\ /\    /\\ ]],
[[/\\    /\\/\\    /\\/\     /\\]],
[[/\\    /\\/\\    /\\/\\\ /\   ]],
[[/\\    /\\/\\    /\\/\     /\\]],
[[/\\   /\\ /\\   /\\ /\      /\]],
[[/\\\\\    /\\\\\    /\\\\ /\\ ]],
[[]],
        },

     buttons = {
       { txt = "  Find File", keys = "Spc f f", cmd = "Telescope find_files" },
       { txt = "  Recent Files", keys = "Spc f o", cmd = "Telescope oldfiles" },
       -- more... check nvconfig.lua file for full list of buttons
     },
   }
}

return M
