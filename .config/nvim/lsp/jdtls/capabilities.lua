local api = vim.api
local utils = require('jdtls.utils')

M = {}

--- Open `jdt://` uri or decompile class contents and load them into the buffer
---
--- Called from a `BufReadCmd` event auto command
---
--- @param client vim.lsp.Client
--- @param fname string
M.open_classfile = function(client, fname)
    local uri
    local use_cmd
    if vim.startswith(fname, "jdt://") then
        uri = fname
        use_cmd = false
    else
        uri = vim.uri_from_fname(fname)
        use_cmd = true
        if not vim.startswith(uri, "file://") then
            return
        end
    end
    local buf = api.nvim_get_current_buf()
    vim.bo[buf].modifiable = true
    vim.bo[buf].swapfile = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "java"

    local timeout_ms = utils.settings.jdt_uri_timeout_ms

    local content
    local handler = function(err, result)
        assert(not err, vim.inspect(err))
        content = result
        local normalized = string.gsub(result, "\r\n", "\n")
        local source_lines = vim.split(normalized, "\n", { plain = true })
        api.nvim_buf_set_lines(buf, 0, -1, false, source_lines)
        vim.bo[buf].modifiable = false
    end

    if use_cmd then
        local command = {
            command = "java.decompile",
            arguments = { uri },
        }
        utils.execute_command(command, handler, client, nil)
    else
        local params = {
            uri = uri,
        }
        client:request("java/classFileContents", params, handler, buf)
    end
    -- Need to block. Otherwise logic could run that sets the cursor to a position
    -- that's still missing.
    vim.wait(timeout_ms, function()
        return content ~= nil
    end)
end

return M
