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
        { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
        "nvimtools/hydra.nvim",
    },
    config = function()
        local dap = require("dap")

        -- ── Breakpoint gutter signs ─────────────────────────────────────
        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticSignError" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticSignWarn" })
        vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticSignInfo" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticSignHint" })
        vim.fn.sign_define("DapStopped", {
            text = "▶",
            texthl = "DiagnosticSignWarn",
            linehl = "Visual",
        })

        -- ── dap-ui: variables/stacks/watches panels ─────────────────────
        -- Opens only when a breakpoint is actually hit (event_stopped), so
        -- plain <leader>tm runs never pop the panels. Closes on session end.
        local dapui = require("dapui")
        dapui.setup()

        -- ── TEST MODE (Hydra): single-key testing + debugging ──────────
        -- Enter with <leader>te (persistent cockpit: run tests, set
        -- breakpoints, step -- stays active across runs) or automatically
        -- when a breakpoint hits (auto-exits when that session ends).
        -- Pink hydra: foreign keys (w, /, gg, arrows...) work normally.
        local Hydra = require("hydra")
        local function run_test(opts)
            local ok = pcall(function()
                require("jdtls").test_nearest_method(opts)
            end)
            if not ok then
                vim.notify("Not in a Java test buffer (jdtls not attached)", vim.log.levels.WARN)
            end
        end
        local function run_test_class()
            local ok = pcall(function()
                require("jdtls").test_class()
            end)
            if not ok then
                vim.notify("Not in a Java test buffer (jdtls not attached)", vim.log.levels.WARN)
            end
        end

        local auto_entered = false
        local test_hydra
        test_hydra = Hydra({
            name = "TEST",
            mode = "n",
            body = "<leader>te",
            hint = [[
 Run:    _m_: test method  _c_: test class   _d_: debug method
 Break:  _b_: toggle       _B_: conditional  _x_: clear all
 Step:   _]_: over  _}_: into  _[_: out  _g_: continue (go)
 Insp:   _?_: hover  _r_: repl  _u_: dap-ui
 _X_: terminate session    <leader>te: exit test mode
]],
            config = {
                color = "pink",
                invoke_on_body = true,
                hint = {
                    position = "bottom",
                    float_opts = { border = "rounded" },
                },
                -- UI lifecycle is bound to the MODE, not to sessions:
                -- open on enter, close on exit. Session start/stop and
                -- test completion never toggle it.
                on_enter = function()
                    dapui.open()
                end,
                on_exit = function()
                    auto_entered = false
                    dapui.close()
                end,
            },
            heads = {
                -- run tests
                { "m", function() run_test() end, { desc = "test method" } },
                { "c", function() run_test_class() end, { desc = "test class" } },
                { "d", function()
                    run_test({ config_overrides = { noDebug = false } })
                end, { desc = "debug method" } },
                -- breakpoints
                { "b", function() dap.toggle_breakpoint() end, { desc = "breakpoint" } },
                { "B", function()
                    dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end, { desc = "conditional" } },
                { "x", function() dap.clear_breakpoints() end, { desc = "clear all" } },
                -- stepping (while paused)
                { "]", function() dap.step_over() end, { desc = "over" } },
                { "}", function() dap.step_into() end, { desc = "into" } },
                { "[", function() dap.step_out() end, { desc = "out" } },
                { "g", function() dap.continue() end, { desc = "continue" } },
                -- inspection
                { "?", function() require("dap.ui.widgets").hover() end, { desc = "hover" } },
                { "r", function() dap.repl.toggle() end, { desc = "repl" } },
                { "u", function() dapui.toggle() end, { desc = "dap-ui" } },
                -- session
                { "X", function() dap.terminate() end, { desc = "terminate" } },
            },
        })

        -- Auto-enter test mode when a breakpoint hits; auto-exit + close
        -- On breakpoint hit: enter TEST mode if not already in it. Track
        -- whether WE entered it (auto_entered) vs the user via <leader>te.
        -- NOTE: no direct dapui calls here -- the UI is driven solely by
        -- hydra on_enter/on_exit, so sessions never toggle it themselves.
        dap.listeners.after.event_stopped["jdtls-dapui"] = function()
            vim.schedule(function()
                if not test_hydra.layer or not test_hydra.layer.active then
                    test_hydra:activate() -- on_enter opens the UI
                    auto_entered = true
                end
            end)
        end
        local function on_session_end()
            vim.schedule(function()
                -- Only auto-exit TEST mode if it was auto-entered by a
                -- breakpoint (on_exit then closes the UI). Manually-entered
                -- mode persists -- UI stays up across runs until <leader>te.
                if auto_entered and test_hydra.layer and test_hydra.layer.active then
                    pcall(function() test_hydra:exit() end)
                end
            end)
        end
        dap.listeners.before.event_terminated["jdtls-dapui"] = on_session_end
        dap.listeners.before.event_exited["jdtls-dapui"] = on_session_end

        -- ── Global DAP keymaps (all under <leader>t*) ───────────────────
        local function tmap(lhs, fn, desc)
            vim.keymap.set("n", lhs, fn, { noremap = true, silent = true, desc = "DAP: " .. desc })
        end
        -- breakpoints
        tmap("<leader>tb", function() dap.toggle_breakpoint() end, "Toggle breakpoint")
        tmap("<leader>tB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, "Conditional breakpoint")
        tmap("<leader>tL", function()
            dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
        end, "Logpoint (print, don't pause)")
        tmap("<leader>tx", function() dap.clear_breakpoints() end, "Clear all breakpoints")
        -- flow control (while paused at a breakpoint)
        -- NOTE: <leader>to belongs to neotest (test output), so stepping
        -- uses motion mnemonics: j = down a line (over), k = back up (out)
        tmap("<leader>tg", function() dap.continue() end, "Continue (go)")
        tmap("<leader>tj", function() dap.step_over() end, "Step over (down a line)")
        tmap("<leader>ti", function() dap.step_into() end, "Step into")
        tmap("<leader>tk", function() dap.step_out() end, "Step out (back up)")
        tmap("<leader>tq", function() dap.terminate() end, "Terminate session (quit)")
        -- inspection
        tmap("<leader>th", function() require("dap.ui.widgets").hover() end, "Hover: value under cursor")
        tmap("<leader>tr", function() dap.repl.toggle() end, "Toggle dap-repl")
        tmap("<leader>tu", function() dapui.toggle() end, "Toggle dap-ui panels")

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("jdtls-test-runner", { clear = true }),
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client or client.name ~= "jdtls" then
                    return
                end

                -- Registers the `java` dap adapter + main-class launch configs
                require("jdtls").setup_dap({ hotcodereplace = "auto" })
                -- Remote-attach configs for locally running coral servers
                -- (bb server starts JDWP: GTAS IAD=5051, GTAS DUB=5052,
                --  GMDS IAD=5061, GMDS DUB=5062 -- see each build.xml jvmarg).
                -- Added in on_ready because setup_dap_main_class_configs replaces
                -- dap.configurations.java when its async main-class scan completes.
                require("jdtls.dap").setup_dap_main_class_configs({
                    on_ready = function()
                        local dap_configs = require("dap").configurations
                        dap_configs.java = dap_configs.java or {}
                        vim.list_extend(dap_configs.java, {
                            {
                                type = "java",
                                request = "attach",
                                name = "Attach: GTAS IAD (:5051)",
                                hostName = "localhost",
                                port = 5051,
                            },
                            {
                                type = "java",
                                request = "attach",
                                name = "Attach: GTAS DUB (:5052)",
                                hostName = "localhost",
                                port = 5052,
                            },
                            {
                                type = "java",
                                request = "attach",
                                name = "Attach: GMDS IAD (:5061)",
                                hostName = "localhost",
                                port = 5061,
                            },
                            {
                                type = "java",
                                request = "attach",
                                name = "Attach: GMDS DUB (:5062)",
                                hostName = "localhost",
                                port = 5062,
                            },
                        })
                    end,
                })

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
