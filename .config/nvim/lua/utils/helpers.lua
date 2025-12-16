local M = {}

-- find element v of l satisfying f(v)
function M.find(l, value)
    for _, v in ipairs(l) do
        if v == value then
            return v
        end
    end
    return nil
end

-- check if a file exists
function M.file_exists(path)
    local stat = vim.loop.fs_stat(path)
    return (stat and stat.type) == "file"
end

-- check if a sym link exists
function M.link_exists(path)
    local stat = vim.loop.fs_lstat(path)
    return (stat and stat.type) == "link"
end

-- wrapper for callback use
function M.get_file_name()
    return vim.api.nvim_buf_get_name(0)
end


--- Check if a plugin is defined in lazy. Useful with lazy loading
--- when a plugin is not necessarily loaded yet.
--- @param plugin string The plugin to search for.
--- @return boolean available # Whether the plugin is available.
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

return M
