local helpers = require("utils.helpers")

local M = {}

-- get all of the current ws folder paths from bemol
function M.get_bemol_ws_folders()
    local bemol_dir = vim.fs.find({ ".bemol" }, { upward = true, type = "directory" })[1]
    local ws_folders_lsp = {}
    if bemol_dir then
        local file = io.open(bemol_dir .. "/ws_root_folders", "r")
        if file then
            for line in file:lines() do
                table.insert(ws_folders_lsp, line)
            end
            file:close()
        end
    end
    return ws_folders_lsp
end

-- Adds all of the ws folders to lsp workspace
--
-- Bemol works by generating lsp config files in each ws which the lsp would
-- ideally pick up automatically. We need to jump through some hoops for ruby-lsp
-- however since bemol is only supported by solargraph
function M.add_all_ws_folder_bemol()
    local ws_folders_lsp = M.get_bemol_ws_folders()
    local current_ws_folders = vim.lsp.buf.list_workspace_folders()
    for _, line in ipairs(ws_folders_lsp) do
        if not helpers.find(current_ws_folders, line) then
            vim.lsp.buf.add_workspace_folder(line)
        end
    end
end

-- parse out the bemol generated ruby farms from the `.solargraph.yml` file
function M.get_bemol_farms_for_single_package()
    local filepath = ".solargraph.yml"
    local ruby_farms = {}

    if vim.fn.filereadable(filepath) == 0 then
        return {}
    end

    local lines = vim.fn.readfile(filepath)

    for _, line in ipairs(lines) do
        local path = string.match(line, "%- (.+)")
        if path then
            table.insert(ruby_farms, vim.trim(path))
        end
    end
    return ruby_farms
end

-- remove build folder link from package directory if there
function M.remove_package_build_link_if_exists(client)
    -- ensures that is only removes if it is a link
    if client and client.name == "ruby-lsp" and helpers.link_exists("build") then
        os.remove("build")
    end
end

return M
