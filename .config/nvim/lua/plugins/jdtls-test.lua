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
        -- ── Test output: non-focused floating popup instead of a split ──
        -- nvim-dap opens the integratedTerminal via terminal_win_cmd. We
        -- return a float (enter=false keeps focus in the code window).
        local function open_term_float(buf)
            -- Reuse the window if this buffer is already displayed
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == buf then
                    return win
                end
            end
            local width = math.floor(vim.o.columns * 0.45)
            local height = math.floor(vim.o.lines * 0.30)
            local win = vim.api.nvim_open_win(buf, false, {
                relative = "editor",
                anchor = "SE",
                row = vim.o.lines - 2,
                col = vim.o.columns,
                width = width,
                height = height,
                style = "minimal",
                border = "rounded",
                title = " test output ",
                title_pos = "center",
            })
            vim.wo[win].winblend = 10
            -- q (in terminal-normal mode) closes the popup
            vim.keymap.set("n", "q", function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end, { buffer = buf, nowait = true, silent = true })
            return win
        end

        local dap = require("dap")
        dap.defaults.fallback.terminal_win_cmd = function()
            local buf = vim.api.nvim_create_buf(false, true) -- unlisted scratch
            local win = open_term_float(buf)
            return buf, win
        end

        -- nvim-dap POOLS terminal buffers: on re-runs it reuses the old
        -- buffer without calling terminal_win_cmd, so no window would
        -- appear. Re-float any dap-terminal buffer when its job starts.
        local term_group = vim.api.nvim_create_augroup("jdtls-test-term-float", { clear = true })
        vim.api.nvim_create_autocmd("TermOpen", {
            group = term_group,
            callback = function(args)
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(args.buf) then
                        return
                    end
                    local name = vim.api.nvim_buf_get_name(args.buf)
                    if name:match("%[dap%-terminal%]") then
                        open_term_float(args.buf)
                    end
                end)
            end,
        })

        -- Auto-close the popup shortly after the test process exits.
        -- Skipped if you've focused the float (reading output); the ✓/✗
        -- summary lives on in dap-repl + quickfix regardless.
        local close_delay_ms = 2000
        vim.api.nvim_create_autocmd("TermClose", {
            group = term_group,
            callback = function(args)
                if not vim.api.nvim_buf_is_valid(args.buf) then
                    return
                end
                if not vim.api.nvim_buf_get_name(args.buf):match("%[dap%-terminal%]") then
                    return
                end
                vim.defer_fn(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if
                            vim.api.nvim_win_is_valid(win)
                            and vim.api.nvim_win_get_buf(win) == args.buf
                            and vim.api.nvim_win_get_config(win).relative ~= "" -- floats only
                            and win ~= vim.api.nvim_get_current_win() -- not while you're in it
                        then
                            pcall(vim.api.nvim_win_close, win, true)
                        end
                    end
                end, close_delay_ms)
            end,
        })

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
