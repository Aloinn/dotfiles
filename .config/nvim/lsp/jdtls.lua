local amazon = require("utils.amazon")
local jdtls_utils = require('jdtls.utils')
local jdtls_capabilities = require('jdtls.capabilities')

local api = vim.api

-- ╭──────────────────────────────────────────────╮
-- │                Local Vars                    │
-- ╰──────────────────────────────────────────────╯

-- All of the paths of various files needed for jdtls

-- The path to my jdtls instalation directory, this is the root directory for many of the files 
-- needed by jdtls and is used in many of the variables below
local jdtls_install = vim.env.HOMEBREW_PREFIX .. "/opt/jdtls"

-- jdtls uses a data directory to cache indexing data. By default it will create this
-- directory automatically in some temporary directory that gets cleared out on system resart.
-- I opt to configure this directory myself because it allows it to persist better, and I always
-- know where it is incase I need to invalidate the cache.
--
-- The location of this directory is something like ~/.cache/nvim/nvim-jdtls_<path_to_workspace>/,
-- but sometimes indexing will break and I'll have to wipe the cache, to be safe I wipe it for all my 
-- projects by running `rm -rf ~/.cache/nvim/jdtls` 
local project_path = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h")
local project_path_hash = string.gsub(project_path, "[/\\:+-]", "_")
local data_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_path_hash

-- The actual jdtls binary
local jdtls_bin = jdtls_install .. "/bin/jdtls"

-- Allows indexing of lombok-generated code
local java_agent = vim.env.HOME .. "/dotfiles/java/lombok/lombok.jar"

-- path to my instalation of the launcher
local launcher_jar = vim.fn.glob(jdtls_install .. "/libexec/plugins/org.eclipse.equinox.launcher_*.jar")

-- Some special configuration for whatever OS I'm using (Mac or Linux)
local os_config = vim.loop.os_uname().sysname == "Darwin" and "config_mac" or "config_linux"
local platform_config = jdtls_install .. "/libexec/" .. os_config

-- If I ever need any java runtimes or bundles, I'll include them here
local runtimes = {}
local bundles = {}

-- ╭──────────────────────────────────────────────╮
-- │                   Command                    │
-- ╰──────────────────────────────────────────────╯

local cmd = {
    jdtls_bin,

    "-XX:+UseParallelGC", -- Better performance for multi-core systems
    "-XX:GCTimeRatio=4", -- Spend less time on GC
    "-XX:AdaptiveSizePolicyWeight=90", -- Optimize for throughput
    "-Dsun.zip.disableMemoryMapping=true", -- Reduce memory pressure
    "-Xms1g", -- Initial heap size
    "-Xmx8g", -- Maximum heap size
    "-XX:+UseStringDeduplication", -- Reduce memory usage for string storage
    "-XX:+OptimizeStringConcat", -- Optimize string concatenation
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "--jvm-arg=-javaagent:" .. java_agent,
    "-jar", launcher_jar,
    "-configuration", platform_config,
    "-data", data_dir,
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
}

-- ╭──────────────────────────────────────────────╮
-- │                 Filetypes                    │
-- ╰──────────────────────────────────────────────╯

local filetypes = {
    "java",
}

-- ╭──────────────────────────────────────────────╮
-- │                   On Init                    │
-- ╰──────────────────────────────────────────────╯

local on_init = function(client, _)
    amazon.add_all_ws_folder_bemol()

    vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
        pattern = { "jdt://*", "*.class" },
        callback = function(_)
            jdtls_capabilities.open_classfile(client, vim.fn.expand("<amatch>"))

            local bufnr = api.nvim_get_current_buf()
            local bufname = api.nvim_buf_get_name(bufnr)
            -- Won't be able to get the correct root path for jdt:// URIs
            -- So need to connect to an existing client
            if vim.startswith(bufname, "jdt://") then
                jdtls_utils.attach_to_active_buf(bufnr, client)
            end
        end,
    })
end

-- ╭──────────────────────────────────────────────╮
-- │                   Settings                   │
-- ╰──────────────────────────────────────────────╯

local settings = {
    java = {
        eclipse = {
            downloadSources = true,
        },
        configuration = {
            updateBuildConfiguration = "automatic",
            runtimes = runtimes,
        },
        maven = {
            downloadSources = true,
        },
        implementationsCodeLens = {
            enabled = true,
        },
        referencesCodeLens = {
            enabled = true,
        },
        references = {
            includeDecompiledSources = true,
            includeAccessors = true,
            includeDeclaration = true,
        },
        quickfix = {
            enabled = true,
        },
        inlayHints = {
            parameterNames = {
                enabled = "all",
            },
        },
        format = {
            enabled = false,
        },
    },
    signatureHelp = {
        enabled = true,
    },
    completion = {
        favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*",
        },
        filteredTypes = {
            "com.sun.*",
            "io.micrometer.shaded.*",
            "java.awt.*",
            "jdk.*",
            "sun.*",
        },
    },
    contentProvider = {
        preferred = "fernflower",
    },
    sources = {
        organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
        },
    },
    codeGeneration = {
        toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
    },
}

-- ╭──────────────────────────────────────────────╮
-- │                    Flags                     │
-- ╰──────────────────────────────────────────────╯

local flags = {
    allow_incremental_sync = true,
}

-- ╭──────────────────────────────────────────────╮
-- │                 Init Options                 │
-- ╰──────────────────────────────────────────────╯

local init_options = {
    bundles = bundles,
    extendedClientCapabilities = {
        classFileContentsSupport = true,
        generateToStringPrompt = true,
        hashCodeEqualsPrompt = true,
    },
}

-- ╭──────────────────────────────────────────────╮
-- │                   Config                     │
-- ╰──────────────────────────────────────────────╯

return {
    cmd = cmd,
    filetypes = filetypes,
    on_init = on_init,
    settings = settings,
    flags = flags,
    init_options = init_options,
}
