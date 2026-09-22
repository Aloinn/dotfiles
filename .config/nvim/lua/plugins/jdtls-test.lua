-- IntelliJ-style JUnit test running/debugging for Java.
--
-- nvim-jdtls is used ONLY for its client-side helpers (test_nearest_method /
-- test_class / setup_dap) -- the language server itself is still started by
-- the native vim.lsp.enable("jdtls") config in lsp/jdtls.lua. The server-side
-- half lives in the bundle jars wired into `bundles` there.
return {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
        "mfussenegger/nvim-dap",
    },
    config = function()
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("jdtls-test-runner", { clear = true }),
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "jdtls" then
                    return
                end

                -- Registers the `java` dap adapter + main-class launch configs
                require("jdtls").setup_dap({ hotcodereplace = "auto" })
                require("jdtls.dap").setup_dap_main_class_configs()

                local opts = { buffer = args.buf, noremap = true, silent = true }
                vim.keymap.set("n", "<leader>tm", function()
                    require("jdtls").test_nearest_method()
                end, vim.tbl_extend("force", opts, { desc = "Run nearest test method (jdtls)" }))
                vim.keymap.set("n", "<leader>tc", function()
                    require("jdtls").test_class()
                end, vim.tbl_extend("force", opts, { desc = "Run test class (jdtls)" }))
                vim.keymap.set("n", "<leader>td", function()
                    require("jdtls").test_nearest_method({ config_overrides = { noDebug = false } })
                end, vim.tbl_extend("force", opts, { desc = "Debug nearest test method (jdtls)" }))
            end,
        })
    end,
}
