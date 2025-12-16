---@type ChadrcConfig
local M = {
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
