---@type ChadrcConfig
local M = {
    ui = {
        transparency = true,
        tabufline = { enabled = false},
        statusline = {
            theme = "vscode_colored",
            -- vscode order + "dap" (JVM/debug-session indicator, hidden when none)
            order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "dap", "diagnostics", "lsp", "cursor", "cwd" },
            modules = {
                dap = function()
                    return require("utils.dap_status").statusline()
                end,
            },
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
