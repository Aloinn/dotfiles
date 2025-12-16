return {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    event = "VimEnter",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",

            -- `build` is used to run some command when the plugin is installed/updated.
            -- This is only run then, not every time Neovim starts up.
            build = "make",

            -- `cond` is a condition used to determine whether this plugin should be
            -- installed and loaded.
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
        { "nvim-telescope/telescope-ui-select.nvim" },

        -- Useful for getting pretty icons, but requires a Nerd Font.
        { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    opts = function()
        dofile(vim.g.base46_cache .. "telescope")
        return {
            defaults = {
                prompt_prefix = "   ",
                selection_caret = " ",
                entry_prefix = " ",
                sorting_strategy = "ascending",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.55,
                    },
                    width = 0.87,
                    height = 0.80,
                },
                mappings = {
                    n = {
                        ["q"] = require("telescope.actions").close,
                        ["<esc>"] = require("telescope.actions").close,
                    },
                    i = {
                        ["<esc>"] = require("telescope.actions").close, 
                    }
                },
            },

            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown(),
                },
            },
        }
    end,
    config = function(_, opts)
        dofile(vim.g.base46_cache .. "telescope")
        require("telescope").setup(opts)

        pcall(require("telescope").load_extension, "fzf")
        pcall(require("telescope").load_extension, "ui-select")

        local map = vim.keymap.set
        local builtin = require("telescope.builtin")

        map("n", "<M-f>h", builtin.help_tags, { desc = "Help" })
        map("n", "<M-f>k", builtin.keymaps, { desc = "Keymaps" })
        map("n", "?", builtin.keymaps, { desc = "Keymaps" })
        map("n", "<M-f>p", builtin.find_files, { desc = "Files" })
        map("n", "<M-p>", builtin.find_files, { desc = "Files" })
        map("n", "<M-f>s", builtin.builtin, { desc = "Select Telescope" })
        map("n", "<M-f>w", builtin.grep_string, { desc = "current Word" })
        map("n", "<M-f>g", builtin.live_grep, { desc = "by Grep" })
        map("n", "<M-f>f", builtin.live_grep, { desc = "by Grep" })
        map("n", "<M-f>d", builtin.diagnostics, { desc = "Diagnostics" })
        map("n", "<M-f>r", builtin.resume, { desc = "Resume" })
        map("n", "<M-f>.", builtin.oldfiles, { desc = 'Recent Files ("." for repeat)' })
        map("n", "<M-f>b", builtin.buffers, { desc = "Buffers" })
        map("n", "<M-b>", builtin.buffers, { desc = "Buffers" })
        map("n", "<M-f>c", builtin.git_commits, { desc = "Commits" })
        map("n", "<M-f>t", builtin.git_status, { desc = "status" })

        map("n", "<M-f>/", function()
            builtin.live_grep({
                grep_open_files = true,
                prompt_title = "Live Grep in Open Files",
            })
        end, { desc = "/ in Open Files" })

        -- Shortcut for searching your Neovim configuration files
        map("n", "<M-f>n", function()
            builtin.find_files({ cwd = vim.fn.stdpath("config") })
        end, { desc = "Neovim files" })

        map("n", "<M-f>/", builtin.current_buffer_fuzzy_find, { desc = "/ Fuzzily search in current buffer" })
    end,
}
