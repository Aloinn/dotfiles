local utils = require("base.utils")
local get_icon = utils.get_icon
local is_available = utils.is_available
local ui = require("base.utils.ui")
local maps = require("base.utils").get_mappings_template()
local M = {}
-- mason-lspconfig.nvim [lsp] -------------------------------------------------
-- WARNING: Don't delete this section, or you won't have LSP keymappings.

--A function we call from the script to start lsp.
--@return table lsp_mappings
function M.lsp_mappings(client, bufnr)
  -- Helper function to check if any active LSP clients
  -- given a filter provide a specific capability.
  -- @param capability string The server capability to check for (example: "documentFormattingProvider").
  -- @param filter vim.lsp.get_clients.filter|nil A valid get_clients filter (see function docs).
  -- @return boolean # `true` if any of the clients provide the capability.
  local function has_capability(capability, filter)
    for _, lsp_client in ipairs(vim.lsp.get_clients(filter)) do
      if lsp_client.supports_method(capability) then return true end
    end
    return false
  end

  local lsp_mappings = require("base.utils").get_mappings_template()

  -- Diagnostics
  lsp_mappings.n["<leader>ld"] =
  { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
  lsp_mappings.n["[d"] = {
    function() vim.diagnostic.jump({ count = -1 }) end,
    desc = "Previous diagnostic",
  }
  lsp_mappings.n["]d"] = {
    function() vim.diagnostic.jump({ count = 1 }) end,
    desc = "Next diagnostic",
  }

  -- Diagnostics
  lsp_mappings.n["gl"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
  if is_available("telescope.nvim") then
    lsp_mappings.n["<leader>lD"] =
      { function() require("telescope.builtin").diagnostics() end, desc = "Diagnostics" }
  end

  -- LSP info
  if is_available("mason-lspconfig.nvim") then
    lsp_mappings.n["<leader>li"] = { "<cmd>LspInfo<cr>", desc = "LSP information" }
  end

  if is_available("none-ls.nvim") then
    lsp_mappings.n["<leader>lI"] = { "<cmd>NullLsInfo<cr>", desc = "Null-ls information" }
  end

  -- Code actions
  lsp_mappings.n["<leader>la"] = {
    function() vim.lsp.buf.code_action() end,
    desc = "LSP code action",
  }
  lsp_mappings.v["<leader>la"] = lsp_mappings.n["<leader>la"]

  -- Codelens
  utils.add_autocmds_to_buffer("lsp_codelens_refresh", bufnr, {
    events = { "InsertLeave" },
    desc = "Refresh codelens",
    callback = function(args)
      if client.supports_method "textDocument/codeLens" then
        if vim.g.codelens_enabled then vim.lsp.codelens.refresh({ bufnr = args.buf }) end
      end
    end,
  })
  if client.supports_method "textDocument/codeLens" then -- on LspAttach
    if vim.g.codelens_enabled then vim.lsp.codelens.refresh({ bufnr = 0 }) end
  end

  lsp_mappings.n["<leader>ll"] = {
    function()
      vim.lsp.codelens.run()
      vim.lsp.codelens.refresh({ bufnr = 0 })
    end,
    desc = "LSP CodeLens run",
  }
  lsp_mappings.n["<leader>uL"] = {
    function() ui.toggle_codelens() end,
    desc = "CodeLens",
  }

  -- Formatting (keymapping)
  local formatting = require("base.utils.lsp").formatting
  local format_opts = require("base.utils.lsp").format_opts
  lsp_mappings.n["<leader>lf"] = {
    function()
      vim.lsp.buf.format(format_opts)
      vim.cmd("checktime") -- Sync buffer with changes
    end,
    desc = "Format buffer",
  }
  lsp_mappings.v["<leader>lf"] = lsp_mappings.n["<leader>lf"]

  -- Formatting (command)
  vim.api.nvim_buf_create_user_command(
    bufnr,
    "Format",
    function() vim.lsp.buf.format(format_opts) end,
    { desc = "Format file with LSP" }
  )

  -- Autoformatting (autocmd)
  local autoformat = formatting.format_on_save
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

  -- guard clauses
  local is_autoformat_enabled = autoformat.enabled
  local is_filetype_allowed = vim.tbl_isempty(autoformat.allow_filetypes or {})
      or vim.tbl_contains(autoformat.allow_filetypes, filetype)
  local is_filetype_ignored = vim.tbl_isempty(
    autoformat.ignore_filetypes or {}
  ) or not vim.tbl_contains(autoformat.ignore_filetypes, filetype)

if is_autoformat_enabled and is_filetype_allowed and is_filetype_ignored then
    utils.add_autocmds_to_buffer("lsp_auto_format", bufnr, {
      events = "BufWritePre", -- Trigger before save
      desc = "Autoformat on save",
      callback = function()
        -- guard clause: has_capability
        if
            not has_capability("textDocument/formatting", { bufnr = bufnr })
        then
          utils.del_autocmds_from_buffer("lsp_auto_format", bufnr)
          return
        end

        -- Get autoformat setting (buffer or global)
        local autoformat_enabled = vim.b.autoformat_enabled
            or vim.g.autoformat_enabled
        local has_no_filter = not autoformat.filter
        local passes_filter = autoformat.filter and autoformat.filter(bufnr)

        -- Use these variables in the if condition
        if autoformat_enabled and (has_no_filter or passes_filter) then
          vim.lsp.buf.format(
            vim.tbl_deep_extend("force", format_opts, { bufnr = bufnr })
          )
        end
      end,
    })

    -- Key mappings for toggling autoformat (buffer/global)
    lsp_mappings.n["<leader>uf"] = {
      function() require("base.utils.ui").toggle_buffer_autoformat() end,
      desc = "Toggle buffer autoformat",
    }
    lsp_mappings.n["<leader>uF"] = {
      function() require("base.utils.ui").toggle_autoformat() end,
      desc = "Toggle global autoformat",
    }
  end

  -- Highlight references when cursor holds
  utils.add_autocmds_to_buffer("lsp_document_highlight", bufnr, {
    {
      events = { "CursorHold", "CursorHoldI" },
      desc = "highlight references when cursor holds",
      callback = function()
        if has_capability("textDocument/documentHighlight", { bufnr = bufnr }) then
          vim.lsp.buf.document_highlight()
        end
      end,
    },
    {
      events = { "CursorMoved", "CursorMovedI", "BufLeave" },
      desc = "clear references when cursor moves",
      callback = function() vim.lsp.buf.clear_references() end,
    },
  })

  -- Other LSP mappings
  lsp_mappings.n["<leader>lL"] = {
    function() vim.api.nvim_command(':LspRestart') end,
    desc = "LSP refresh",
  }

  -- Goto definition / declaration
  lsp_mappings.n["gd"] = {
    function() vim.lsp.buf.definition() end,
    desc = "Goto definition of current symbol",
  }
  lsp_mappings.n["gD"] = {
    function() vim.lsp.buf.declaration() end,
    desc = "Goto declaration of current symbol",
  }

  -- Goto implementation
  lsp_mappings.n["gI"] = {
    function() vim.lsp.buf.implementation() end,
    desc = "Goto implementation of current symbol",
  }

  -- Goto type definition
  lsp_mappings.n["gT"] = {
    function() vim.lsp.buf.type_definition() end,
    desc = "Goto definition of current type",
  }

  -- Goto references
  lsp_mappings.n["<leader>lR"] = {
    function() vim.lsp.buf.references() end,
    desc = "Hover references",
  }
  lsp_mappings.n["gr"] = {
    function() vim.lsp.buf.references() end,
    desc = "References of current symbol",
  }

  -- Goto help
  local lsp_hover_config = require("base.utils.lsp").lsp_hover_config
  lsp_mappings.n["gh"] = {
    function()
      vim.lsp.buf.hover(lsp_hover_config)
    end,
    desc = "Hover help",
  }
  lsp_mappings.n["gH"] = {
    function() vim.lsp.buf.signature_help(lsp_hover_config) end,
    desc = "Signature help",
  }

  lsp_mappings.n["<leader>lh"] = {
    function() vim.lsp.buf.hover(lsp_hover_config) end,
    desc = "Hover help",
  }
  lsp_mappings.n["<leader>lH"] = {
    function() vim.lsp.buf.signature_help(lsp_hover_config) end,
    desc = "Signature help",
  }

  -- Goto man
  lsp_mappings.n["gm"] = {
    function() vim.api.nvim_feedkeys("K", "n", false) end,
    desc = "Hover man",
  }
  lsp_mappings.n["<leader>lm"] = {
    function() vim.api.nvim_feedkeys("K", "n", false) end,
    desc = "Hover man",
  }

  -- Rename symbol
  lsp_mappings.n["<leader>lr"] = {
    function() vim.lsp.buf.rename() end,
    desc = "Rename current symbol",
  }

  -- Toggle inlay hints
  if vim.b.inlay_hints_enabled == nil then vim.b.inlay_hints_enabled = vim.g.inlay_hints_enabled end
  if vim.b.inlay_hints_enabled then vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) end
  lsp_mappings.n["<leader>uH"] = {
    function() require("base.utils.ui").toggle_buffer_inlay_hints(bufnr) end,
    desc = "LSP inlay hints (buffer)",
  }

  -- Toggle semantic tokens
  if vim.g.semantic_tokens_enabled then
    vim.b[bufnr].semantic_tokens_enabled = true
    lsp_mappings.n["<leader>uY"] = {
      function() require("base.utils.ui").toggle_buffer_semantic_tokens(bufnr) end,
      desc = "LSP semantic highlight (buffer)",
    }
  else
    client.server_capabilities.semanticTokensProvider = nil
  end

  -- LSP based search
  lsp_mappings.n["<leader>lS"] = { function() vim.lsp.buf.workspace_symbol() end, desc = "Search symbol in workspace" }
  lsp_mappings.n["gS"] = { function() vim.lsp.buf.workspace_symbol() end, desc = "Search symbol in workspace" }

  -- LSP telescope
  if is_available("telescope.nvim") then -- setup telescope mappings if available
    if lsp_mappings.n.gd then lsp_mappings.n.gd[1] = function() require("telescope.builtin").lsp_definitions() end end
    if lsp_mappings.n.gI then
      lsp_mappings.n.gI[1] = function() require("telescope.builtin").lsp_implementations() end
    end
    if lsp_mappings.n.gr then lsp_mappings.n.gr[1] = function() require("telescope.builtin").lsp_references() end end
    if lsp_mappings.n["<leader>lR"] then
      lsp_mappings.n["<leader>lR"][1] = function() require("telescope.builtin").lsp_references() end
    end
    if lsp_mappings.n.gy then
      lsp_mappings.n.gy[1] = function() require("telescope.builtin").lsp_type_definitions() end
    end
    if lsp_mappings.n["<leader>lS"] then
      lsp_mappings.n["<leader>lS"][1] = function()
        vim.ui.input({ prompt = "Symbol Query: (leave empty for word under cursor)" }, function(query)
          if query then
            -- word under cursor if given query is empty
            if query == "" then query = vim.fn.expand "<cword>" end
            require("telescope.builtin").lsp_workspace_symbols {
              query = query,
              prompt_title = ("Find word (%s)"):format(query),
            }
          end
        end)
      end
    end
    if lsp_mappings.n["gS"] then
      lsp_mappings.n["gS"][1] = function()
        vim.ui.input({ prompt = "Symbol Query: (leave empty for word under cursor)" }, function(query)
          if query then
            -- word under cursor if given query is empty
            if query == "" then query = vim.fn.expand "<cword>" end
            require("telescope.builtin").lsp_workspace_symbols {
              query = query,
              prompt_title = ("Find word (%s)"):format(query),
            }
          end
        end)
      end
    end
  end

  return lsp_mappings
end
utils.set_mappings(maps)

return M
