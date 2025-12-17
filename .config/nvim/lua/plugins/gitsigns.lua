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
                -- map("n", ",s", gitsigns.stage_hunk, { desc = "hunk stage" })
                map("n", ",r", gitsigns.reset_hunk, { desc = "hunk reset" })
                -- map("n", ",S", gitsigns.stage_buffer, { desc = "buffer stage" })
                -- map("n", ",R", gitsigns.reset_buffer, { desc = "buffer reset" })
                map("n", ",p", gitsigns.preview_hunk, { desc = "hunk preview" })
                map("n", ",b", gitsigns.blame_line, { desc = "blame line" })
                -- map("n", ",d", gitsigns.diffthis, { desc = "diff against index" })
                map("n", ",[", "<cmd>Gitsigns nav_hunk prev<CR>", { desc = "hunk prev" })
                map("n", ",]", "<cmd>Gitsigns nav_hunk next<CR>", { desc = "hunk next" })
                map("n", ",d", function()
                    gitsigns.diffthis("@")
                end, { desc = "diff against last commit" })

                -- Toggles
                map("n", "<M-e>b", gitsigns.toggle_current_line_blame, { desc = "toggle blame line" })
                -- map("n", "<leader>tD", gitsigns.preview_hunk_inline, { desc = "[T]oggle git show [D]eleted" })
            end,
        }
    end,
}
