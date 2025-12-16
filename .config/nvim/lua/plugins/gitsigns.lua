return {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
        dofile(vim.g.base46_cache .. "git")
        return {
            auto_attach = true,
            signs = {
                delete = { text = "󰍵" },
                changedelete = { text = "󱕖" },
            },
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- normal mode
                map("n", "<M-g>s", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
                map("n", "<M-g>r", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
                map("n", "<M-g>S", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
                map("n", "<M-g>u", gitsigns.stage_hunk, { desc = "git [u]ndo stage hunk" })
                map("n", "<M-g>R", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
                map("n", "<M-g>p", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
                map("n", "<M-g>b", gitsigns.blame_line, { desc = "git [b]lame line" })
                map("n", "<M-g>d", gitsigns.diffthis, { desc = "git [d]iff against index" })
                map("n", "<M-g>n", gitsigns.diffthis, { desc = "git [d]iff against index" })
                map("n", "<M-g>[", "<cmd>Gitsigns nav_hunk next<CR>", { desc = "git [d]iff against index" })
--                map("n", "<M-g>]", gitsigns.nav_hunk('prev'), { desc = "git [d]iff against index" })
                map("n", "<M-g>D", function()
                    gitsigns.diffthis("@")
                end, { desc = "git [D]iff against last commit" })

                -- Toggles
                map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
                map("n", "<leader>tD", gitsigns.preview_hunk_inline, { desc = "[T]oggle git show [D]eleted" })
            end,
        }
    end,
}
