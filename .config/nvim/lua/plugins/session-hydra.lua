-- SESSION hydra: manage self_session project sessions from one place.
-- Body: <leader>ss  (pink hydra, same style as the TEST hydra in
-- jdtls-test.lua -- foreign keys pass through).
--
-- Prompting heads (new / switch / delete) exit the hydra first: pink
-- hydras intercept head keys globally, which fights vim.ui.input /
-- vim.ui.select focus.
return {
    "nvimtools/hydra.nvim",
    keys = { { "<leader>ss", desc = "Session mode (hydra)" } },
    config = function()
        local Hydra = require("hydra")
        local ss = require("self_session")

        local function prompt_new()
            vim.ui.input({ prompt = "New session name: " }, function(input)
                if input and input ~= "" then
                    ss.new_session(input)
                end
            end)
        end

        local function pick_switch()
            local names = vim.tbl_filter(function(n)
                return n ~= ss.current_session()
            end, ss.sessions())
            if #names == 0 then
                vim.notify("self_session: no other sessions (n = new)", vim.log.levels.INFO)
                return
            end
            vim.ui.select(names, { prompt = "Switch to session:" }, function(choice)
                if choice then
                    ss.switch(choice)
                end
            end)
        end

        local function pick_delete()
            local names = vim.tbl_filter(function(n)
                return n ~= ss.current_session()
            end, ss.sessions())
            if #names == 0 then
                vim.notify("self_session: no other sessions to delete", vim.log.levels.INFO)
                return
            end
            vim.ui.select(names, { prompt = "Delete session:" }, function(choice)
                if choice then
                    ss.delete_session(choice)
                end
            end)
        end

        local function list_sessions()
            local lines = {}
            for _, n in ipairs(ss.sessions()) do
                table.insert(lines, (n == ss.current_session() and "* " or "  ") .. n)
            end
            if #lines == 0 then
                lines = { "(no sessions saved yet)" }
            end
            vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "self_session" })
        end

        Hydra({
            name = "SESSION",
            mode = "n",
            body = "<leader>ss",
            hint = [[
 _s_: switch   _n_: new   _d_: delete
 _l_: list     _w_: save now
 _q_/_<Esc>_: exit
]],
            config = {
                color = "pink",
                invoke_on_body = true,
                hint = {
                    position = "bottom",
                    float_opts = { border = "rounded" },
                },
            },
            heads = {
                { "s", pick_switch, { desc = "switch", exit = true } },
                { "n", prompt_new, { desc = "new", exit = true } },
                { "d", pick_delete, { desc = "delete", exit = true } },
                { "l", list_sessions, { desc = "list" } },
                { "w", function()
                    ss.save()
                    vim.notify("self_session: saved '" .. ss.current_session() .. "'")
                end, { desc = "save now" } },
                { "q", nil, { desc = "exit", exit = true, nowait = true } },
                { "<Esc>", nil, { desc = false, exit = true, nowait = true } },
            },
        })
    end,
}
