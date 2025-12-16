local amazon = require("utils.amazon")

-- ╭──────────────────────────────────────────────╮
-- │                   Command                    │
-- ╰──────────────────────────────────────────────╯

local cmd = { "solargraph", "stdio" }

-- ╭──────────────────────────────────────────────╮
-- │                 Filetypes                    │
-- ╰──────────────────────────────────────────────╯

local filetypes = { "ruby", "eruby" }

-- ╭──────────────────────────────────────────────╮
-- │                 Init Options                 │
-- ╰──────────────────────────────────────────────╯

local init_options = { formatting = false }

-- ╭──────────────────────────────────────────────╮
-- │                   On Init                    │
-- ╰──────────────────────────────────────────────╯

local on_init = function(_, _)
    amazon.add_all_ws_folder_bemol()
end

-- ╭──────────────────────────────────────────────╮
-- │                 Settings                     │
-- ╰──────────────────────────────────────────────╯

local settings = {
    solargraph = {
        diagnostics = false,
    },
}

-- ╭──────────────────────────────────────────────╮
-- │                   Config                     │
-- ╰──────────────────────────────────────────────╯

return {
    cmd = cmd,
    filetypes = filetypes,
    init_options = init_options,
    on_init = on_init,
    settings = settings,
}
