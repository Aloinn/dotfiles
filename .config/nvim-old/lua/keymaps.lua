-- tree
vim.keymap.set("n", "<leader>e", ":Neotree toggle float<cr>", { noremap = true, silent = true})
vim.keymap.set("n", "<M-e>", ":Neotree toggle left<cr>", { noremap = true, silent = true})
-- vim.keymap.set("n", "<M-e>", ":Neotree", { noremap = true, silent = true})
vim.keymap.set('n', '<End>', 'g$', { noremap = true, silent = true })
vim.keymap.set('n', '<Home>', 'g0', { noremap = true, silent = true })

vim.keymap.set('n', 'D', 'dd', { noremap = true })
vim.keymap.set('n', 'q', ':q<cr>')
-- Hop
vim.keymap.set('n', 'f', '<cmd>HopWord<cr>', { noremap = true })
vim.keymap.set('v', 'f', '<cmd>HopWord<cr>', { noremap = true })
vim.keymap.set('n', '<A-1>', '<cmd>HopWord<cr>', { noremap = true })
-- vim.keymap.set('v', '<cr>', '<cmd>HopWord<cr>', { noremap = true)
-- vim.keymap.set('n', '<cr>', '<cmd>HopWord<cr>', { noremap = true })

-- Telescope
vim.keymap.set('n', '<D-p>', function()
  require("telescope.builtin").find_files({
    find_command = { "rg", "--files", "--hidden", "--iglob", "!.git", "--glob", "!.gitignore" },
  })
end, { desc = "Find files (exclude .gitignored)" }) 
-- vim.keymap.set('n', '<M-F>', ':Telescope live_grep search_dirs=. <cr>')
vim.keymap.set('n', '<M-f>', ':Telescope live_grep search_dirs={vim.fn.expand("%:p")} <cr>')
vim.keymap.set('n', '<M-b>', ':Telescope buffers <cr>')
vim.keymap.set("n", "<M-f>", function()
  require("telescope").extensions.project.project {}
end, { desc = "Telescope Projects" })

-- vim.keymap.set('n', 'a', 'a', { noremap = true })
-- vim.keymap.set('n', 'a', 'a', { noremap = true })

-- vim.keymap.set('n', 'a', 'a', { noremap = true })
--
vim.keymap.set('n', '<leader>r', ':source <cr>')

-- Buffers
vim.keymap.set('n', '<leader>w', ':bd <cr>')

