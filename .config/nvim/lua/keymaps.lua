-- tree
vim.keymap.set("n", "<leader>e", ":Neotree toggle float<cr>", { noremap = true, silent = true})
vim.keymap.set("n", "<C-e>", ":Neotree toggle left<cr>", { noremap = true, silent = true})
vim.keymap.set("n", "<M-e>", ":Neotree", { noremap = true, silent = true})
vim.keymap.set('n', '<End>', 'g$', { noremap = true, silent = true })
vim.keymap.set('n', '<Home>', 'g0', { noremap = true, silent = true })

-- Home and End keys
vim.keymap.set('n', 'D<End>', 'd$', { noremap = true, silent = true })
vim.keymap.set('n', 'D<Home>', 'd0', { noremap = true, silent = true })

-- rebind d into D
local motions = { 'w', 'e', 'b', 'ge', '$', '0', '^', 'G', 'H', 'M', 'L' }

for _, motion in ipairs(motions) do
  vim.keymap.set('n', 'D' .. motion, 'd' .. motion, { noremap = true, silent = true })
end
vim.keymap.set('n', 'D', '<Nop>', { noremap = true, silent = true })


-- WASD navigation LOL --
vim.keymap.set('n', 'w', 'k', { noremap = true })
vim.keymap.set('n', 'a', '<Plug>(smartword-b)', { noremap = true })
vim.keymap.set('n', 's', 'j', { noremap = true })
vim.keymap.set('n', 'd', '<Plug>(smartword-w)', { noremap = true })
vim.keymap.set('n', 'I', 'a', { noremap = true })
vim.keymap.set('n', 'W', '3k', { noremap = true, silent = true })  -- jump up 10 lines
vim.keymap.set('n', 'S', '3j', { noremap = true, silent = true })  -- jump down 10 line

-- Normal mode: jump by :ord
-- vim.keymap.set('n', '<A-Left>', 'b', { noremap = true, silent = true })  -- back a word
-- vim.keymap.set('n', '<A-Right>', 'w', { noremap = true, silent = true }) -- forward a word

-- Insert mode: move cursor by word
-- vim.keymap.set('i', '<A-Left>', '<C-Left>', { noremap = true, silent = true })
-- vim.keymap.set('i', '<A-Right>', '<C-Right>', { noremap = true, silent = true })

-- Hop
vim.keymap.set('n', 'f', '<cmd>HopWord<cr>', { noremap = true })
vim.keymap.set('v', 'f', '<cmd>HopWord<cr>', { noremap = true })
vim.keymap.set('n', '<A-1>', '<cmd>HopWord<cr>', { noremap = true })

-- Telescope
vim.keymap.set('n', '<M-p>', ':Telescope find_files hidden=true no_ignore=true <cr>')
vim.keymap.set('n', '<M-F>', ':Telescope live_grep search_dirs=. <cr>')
vim.keymap.set('n', '<M-f>', ':Telescope live_grep search_dirs={vim.fn.expand("%:p")} <cr>')
vim.keymap.set('n', '<leader>b', ':Telescope buffers <cr>')
-- vim.keymap.set('n', 'a', 'a', { noremap = true })
-- vim.keymap.set('n', 'a', 'a', { noremap = true })

-- vim.keymap.set('n', 'a', 'a', { noremap = true })
--
vim.keymap.set('n', '<leader>r', ':source <cr>')

-- Buffers
vim.keymap.set('n', '<leader>w', ':bd <cr>')

