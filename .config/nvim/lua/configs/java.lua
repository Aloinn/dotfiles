-- ~/.config/nvim/ftplugin/java.lua
-- helper function for checking if a table contains a value
local function contains(table, value)
    for _, table_value in ipairs(table) do
        if table_value == value then
            return true
        end
    end

    return false
end

-- helper function for finding a filename in a directory which matches
-- the specified pattern
local function find_file(directory, pattern)
    local filename_found = ''
    local pfile = io.popen('ls "' .. directory .. '"')

    if (pfile == nil) then
        return ''
    end

    for filename in pfile:lines() do
        if (string.find(filename, pattern) ~= nil) then
            filename_found = filename
            break
        end
    end

    return filename_found
end

-- gathers all of the bemol-generated files and adds them to the LSP workspace
local function bemol()
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

        for _, line in ipairs(ws_folders_lsp) do
            if not contains(vim.lsp.buf.list_workspace_folders(), line) then
                vim.lsp.buf.add_workspace_folder(line)
            end
        end
    end
end

require("lazy").load({ plugins = { "nvim-jdtls" } })
local jdtls = require("jdtls")
local jdtls_setup = require "jdtls.setup"

local home = os.getenv("HOME")
local root_markers = { ".bemol", }
local root_dir = jdtls_setup.find_root(root_markers)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name
local path_to_mason_packages = home .."/.local/share/nvim/mason/packages"
local path_to_jdtls = path_to_mason_packages .. "/jdtls"
local os_type = vim.fn.has("macunix") and "mac" or "linux"
local path_to_config = path_to_jdtls .. "/config_" .. os_type
local path_to_lombok = path_to_jdtls .. "/lombok.jar"
local path_to_plugins = path_to_jdtls .. "/plugins/"
-- the eclipse jar is suffixed with a bunch of version nonsense, so we find it by pattern matching
local path_to_jar = path_to_plugins .. find_file(path_to_plugins, "org.eclipse.equinox.launcher_")

local bundles = {
  vim.fn.glob(home .. "/dotfiles/java/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar", 1)
}
vim.list_extend(bundles, vim.split(vim.fn.glob(home.."/dotfiles/java/vscode-java-test/server/*.jar", 1), "\n"))
local config = {
    cmd = {
        -- assumes the java binary is in your PATH and at least java17;
        -- if not, specify the full path to the binary
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xmx1g",
        "-javaagent:" .. path_to_lombok,
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",

        "-jar",
        path_to_jar,

        "-configuration",
        path_to_config,

        "-data",
        workspace_dir,
    },

    root_dir = root_dir,

    capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    },

    settings = {
        java = {
            references = {
                includeDecompiledSources = true,
            },
            eclipse = {
                downloadSources = true,
            },
            maven = {
                downloadSources = true,
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
        }
    },

    -- run our bemol function when the LSP attaches to the buffer
    on_attach = bemol,
    init_options = {
        bundles = bundles 
    }
}


vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    jdtls.start_or_attach(config)
    set_java_buffers()
  end,
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile" ,"BufEnter"}, {
  pattern = "java",
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name:match("^jdt://") then
      vim.schedule(function()
        vim.bo[args.buf].filetype = "java"
      end)
    end
  end,
})

local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local pcolors = {
  "TelescopeResultsClass",
  "TelescopeResultsConstant",
  "TelescopeResultsOperator",
  "TelescopeResultsVariable",
  "TelescopeResultsClass",
  "TelescopeResultsComment"
}

function set_java_buffers()
  local entry_maker = function(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local displayname = name:match("^.+/(.+)$") or name
    local repo = name:match("src/([^/]+)")
    local decompiled = false
    if name:match("^jdt://") then
      -- name = "[JDT] " .. (name:match("[^/]+$") or "Decompiled")
      repo, class = name:match("([^%%]+)%%(.*)")
      displayname = name:match(".*%((.*)$")
      repo = repo:match("([^%-]+)"):gsub("^jdt://contents/", "")
      repo = repo:gsub("/.*", "")
      decompiled = true
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        {},
        {},
        {},
      }
    }
    -- local file_name  tostring(entry.value),
    return {
      value = bufnr,
      ordinal = name,
      display = function(entry)
        return displayer {
          {'['..repo..']', pcolors[2]},
          {displayname, pcolors[decompiled and 6 or 0]},
        }
      end,
      path = name,
      bufnr = bufnr
    }
  end

  builtin.buffers = function(opts)
    opts = opts or {}

    local bufnrs = vim.tbl_filter(function(b)
      return vim.api.nvim_buf_is_loaded(b)
    end, vim.api.nvim_list_bufs())

    pickers.new(opts, {
      prompt_title = "Buffers",
      
      finder = finders.new_table({
        results = bufnrs,
        entry_maker = entry_maker 
      }),
      -- previewer = conf.buffer_previewer(opts),
      sorter = conf.generic_sorter(opts),
    }):find()
  end
end
