local x = vim.diagnostic.severity

-- ╭──────────────────────────────────────────────╮
-- │           Language Server Settings           │
-- ╰──────────────────────────────────────────────╯

local enabled_servers = {
    "lua-language-server",
    "pyright",
    "ruby-lsp",
    -- "solargraph",
    "jdtls",
    "yaml-language-server",
    "bash-language-server",
    "marksman",
    "rust-analyzer",
}

-- ╭──────────────────────────────────────────────╮
-- │                   Themeing                   │
-- ╰──────────────────────────────────────────────╯

dofile(vim.g.base46_cache .. "lsp")

-- ╭──────────────────────────────────────────────╮
-- │              Diagnostic Config               │
-- ╰──────────────────────────────────────────────╯

vim.diagnostic.config({
    virtual_text = { prefix = "" },
    signs = {
        text = {
            [x.ERROR] = "󰅙",
            [x.WARN] = "",
            [x.INFO] = "󰋼",
            [x.HINT] = "󰌵",
        },
    },
    underline = true,
    float = { border = "single" },
})

-- ╭──────────────────────────────────────────────╮
-- │                 LspAttach                    │
-- ╰──────────────────────────────────────────────╯

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        -- LspInfo
        vim.api.nvim_create_user_command(
            "LspInfo",
            ":checkhealth vim.lsp",
            { desc = "Alias to `:checkhealth vim.lsp`" }
        )

        -- LspLog
        vim.api.nvim_create_user_command("LspLog", function()
            vim.cmd(string.format("tabnew %s", vim.lsp.log.get_filename()))
        end, {
            desc = "Opens the Nvim LSP client log.",
        })

        -- Keymaps
        local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
        map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
        map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
        map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

        -- client config
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
            vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
                callback = function(args)
                    vim.lsp.codelens.refresh({ bufnr = args.buf })
                end,
            })
        end
    end,
})

-- ╭──────────────────────────────────────────────╮
-- │                 Capabilities                 │
-- ╰──────────────────────────────────────────────╯

local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem = {
    documentationFormat = { "markdown", "plaintext" },
    snippetSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true,
    labelDetailsSupport = true,
    deprecatedSupport = true,
    commitCharactersSupport = true,
    tagSupport = { valueSet = { 1 } },
    resolveSupport = {
        properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
        },
    },
}

-- ╭──────────────────────────────────────────────╮
-- │                 Root Markers                 │
-- ╰──────────────────────────────────────────────╯

local root_markers = {
    {
        -- Bemol generates a `.classpath` file which uses paths relative to the
        -- Brazil ws root. This means our root needs to be the Brazil ws root.
        "packageInfo",
        ".bemol",
    },
    {
        ".git",
        "Config",
    },
}

-- ╭──────────────────────────────────────────────╮
-- │                   Config                     │
-- ╰──────────────────────────────────────────────╯

vim.lsp.config("*", {
    capabilities = capabilities,
    root_markers = root_markers,
})
vim.lsp.enable(enabled_servers)
