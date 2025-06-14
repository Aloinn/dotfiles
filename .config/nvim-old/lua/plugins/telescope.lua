return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-hop.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local hop = telescope.extensions.hop

    telescope.setup{
			extensions = {
    		project = {
      		base_dirs = {
						{'~/w', max_depth = 2},
        		{ '~/dotfiles', max_depth = 2 }
      		},
      		hidden_files = true, -- show hidden files
      		theme = "dropdown",
      		order_by = "recent",
      		search_by = "title",
      		sync_with_nvim_tree = true,
      		-- default for `project` extension
      		-- on_project_selected = function(prompt_bufnr) end
    		}
  		},
      defaults = {
        mappings = {
					n = {
						["q"] = 'close',
						["f"] = hop.hop,
					},
          i = {
            -- IMPORTANT: map <C-h> to hop.hop extension
            ["<M-h>"] = hop.hop,
            -- custom hop loop to multi selects and send selected entries to quickfix list
            ["<C-space>"] = function(prompt_bufnr)
              local opts = {
                callback = actions.toggle_selection,
                loop_callback = actions.send_selected_to_qflist,
              }
              hop._hop_loop(prompt_bufnr, opts)
            end,
          },
        },
      },
    }

    telescope.load_extension("hop")
		telescope.load_extension("project")
  end,
}

