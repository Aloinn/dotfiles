-- This is where I put keymaps that I want to load on startup.
-- Alternatively, other keymaps may be in their respective plugin file.
local map = vim.keymap.set
-- ╭──────────────────────────────────────────────╮
-- │                  Genral                     │
-- ╰──────────────────────────────────────────────╯
map("n", "D", "dd")
map("n", "<backspace>", "<C-o>")
-- map("n", ";", ":", { desc = "CMD enter command mode"})
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "Q", "<cmd>:bdelete<cr>", { desc = "close" })

-- vnoremap < <gv
-- vnoremap > >gv
map("x", "<S-Tab>", "<gv", { desc = "unindent line" })
map("x", "<Tab>", ">gv", { desc = "indent line" })
map("n", "<Tab>", ">>", { desc = "indent line" })
map("n", "<S-Tab>", "<<", { desc = "unindent line" })

map("n", "U", "<C-r>", { desc = "redo" })
map("n", "<M-z>", "u", { desc = "undo" })
map("n", "<M-Z>", "<C-r>", { desc = "redo" })

map("n", "<M-/>", "gcc", { desc = "comment", remap = true})
map("x", "<M-/>", "gc", { desc = "uncomment", remap = true})
-- ╭──────────────────────────────────────────────╮
-- │                  Navigation                  │
-- ╰──────────────────────────────────────────────╯

map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", { desc = "window up" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", { desc = "window right" })

map("i", "<C-a>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })
map("i", "<C-l>", "<Right>", { desc = "move right" })

-- ╭──────────────────────────────────────────────╮
-- │                  Tabufline                   │
-- ╰──────────────────────────────────────────────╯

map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

map("n", "<M-]>", function()
    require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<M-[>", function()
    require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<leader>x", function()
    require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- ╭──────────────────────────────────────────────╮
-- │                  WhichKey                    │
-- ╰──────────────────────────────────────────────╯

map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "whichkey query lookup" })

-- ╭──────────────────────────────────────────────╮
-- │                    Oil                       │
-- ╰──────────────────────────────────────────────╯

-- map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- ╭──────────────────────────────────────────────╮
-- │               Global Toggles                 │
-- ╰──────────────────────────────────────────────╯

-- map("n", "<M-e>e", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })

-- map("n", "<M-e>d", function()
--     vim.diagnostic.enable(not vim.diagnostic.is_enabled())
-- end, { desc = "[T]oggle [D]iagnostics" })

map("n", "<M-e>n", function()
    -- Toggling on always turns relativenumber on
    if vim.wo.number or vim.wo.relativenumber then
        vim.wo.number = false
        vim.wo.relativenumber = false
    else
        vim.wo.number = true
        vim.wo.relativenumber = true
    end
end, { desc = "Line number" })

map("n", "<M-e>r", function()
    -- Only toggle relativenumber if number is on
    if vim.wo.number then
        vim.wo.relativenumber = not vim.wo.relativenumber
    end
end, { desc = "Relative number" })

-- map("n", "<M-e>c", "<cmd>NvCheatsheet<CR>", { desc = "[T]oggle [C]heatsheet" })
--
-- map("n", "<M-e>h", function()
--     require("nvchad.themes").open()
-- end, { desc = "[T]elescope nvchad t[H]emes" })
