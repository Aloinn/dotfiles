local api = vim.api

local M = {
    settings = {
        jdt_uri_timeout_ms = 5000,
    },
}

--- Determines if jdtls should attach to the given buffer
---
--- @param bufnr integer
--- @return boolean
local may_jdtls_buf = function(bufnr)
    if vim.bo[bufnr].filetype == "java" then
        return true
    end
    local fname = api.nvim_buf_get_name(bufnr)
    return vim.endswith(fname, "build.gradle") or vim.endswith(fname, "pom.xml")
end

--- Executes an arbitrary client command
---
--- @param command any
--- @param callback any
--- @param client vim.lsp.Client
--- @param bufnr integer | nil
--- @return any
M.execute_command = function(command, callback, client, bufnr)
    local command_provider = client.server_capabilities.executeCommandProvider
    local commands = type(command_provider) == "table" and command_provider.commands or {}

    if not vim.tbl_contains(commands, command.command) then
        vim.notify("LSP client with ID " .. client.id .. " does not support " .. command.command, vim.log.levels.ERROR)
        return
    end

    local co
    if not callback then
        co = coroutine.running()
        if co then
            callback = function(err, resp)
                coroutine.resume(co, err, resp)
            end
        end
    end
    client:request("workspace/executeCommand", command, callback, bufnr)
    if co then
        return coroutine.yield()
    end
end

--- Attach the client to bufnr
---
--- @param bufnr integer
--- @param client vim.lsp.Client
--- @return integer | nil
function M.attach_to_active_buf(bufnr, client)
    local try_attach = function(buf)
        if not may_jdtls_buf(buf) then
            return nil
        end
        if client then
            vim.lsp.buf_attach_client(bufnr, client.id)
            return client.id
        end
        return nil
    end

    local altbuf = vim.fn.bufnr("#", -1)
    if altbuf and altbuf > 0 then
        local client_id = try_attach(altbuf)
        if client_id then
            return client_id
        end
    end

    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) then
            local client_id = try_attach(buf)
            if client_id then
                return client_id
            end
        end
    end
    print("No active LSP client found to use for jdt:// document")
    return nil
end

return M
