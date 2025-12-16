return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mfussenegger/nvim-jdtls",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        'WhoIsSethDaniel/mason-tool-installer.nvim',
    },

    config = function()
        local lspconfig = require("lspconfig")
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local mason_tool_installer = require("mason-tool-installer")


        local default_capabilities = vim.lsp.protocol.make_client_capabilities()

        local server_configs = {
            -- place language server names and their configuration here as a key-value pair
        }

        mason.setup()

        local mason_ensure_installed = vim.tbl_keys(server_configs or {})
        vim.list_extend(
            mason_ensure_installed,
            {
              "jdtls"
                -- place other packages you want to install but not configure with mason here
                -- e.g. language servers not configured with nvim-lspconfig, linters, formatters, etc.
            }
        )
        mason_tool_installer.setup({
            ensure_installed = mason_ensure_installed
        })

        mason_lspconfig.setup({
            handlers = {
                ['jdtls'] = function() end,
                function(server_name)
                    local server_config = server_configs[server_name] or {}
                    server_config.capabilities = vim.tbl_deep_extend(
                        "force",
                        default_capabilities,
                        server_config.capabilities or {}
                    )
                    lspconfig[server_name].setup(server_config)
                end
            },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("lsp-attach-keybinds", { clear = true }),
            callback = function(e)
                local keymap = function(keys, func)
                    vim.keymap.set("n", keys, func, { buffer = e.buf })
                end
                local builtin = require("telescope.builtin")

                -- keymap("<leader>ggd", builtin.lsp_definitions)
                -- keymap("<leader>ggc", vim.lsp.buf.declaration)
                -- keymap("<leader>ggr", builtin.lsp_references)
                -- keymap("<leader>ggI", builtin.lsp_implementations)
                -- keymap("<leader>ggD", builtin.lsp_type_definitions)
                -- keymap("<leader>ds", builtin.lsp_document_symbols)
                -- keymap("<leader>ws", builtin.lsp_dynamic_workspace_symbols)
                -- keymap("<leader>rn", vim.lsp.buf.rename)
                -- keymap("<leader>ca", vim.lsp.buf.code_action)
                -- keymap("K", vim.lsp.buf.hover)
            end
        })
    end
}
