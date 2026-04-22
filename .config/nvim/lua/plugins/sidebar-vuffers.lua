-- Custom sidebar.nvim section: vuffers-like buffer manager
-- Supports: open, delete, pin, reorder buffers

local pinned = {}
local order_override = {} -- bufnr -> position

local function get_buffers()
  local bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr)
      and vim.bo[bufnr].buflisted
      and vim.bo[bufnr].buftype == ""
      and vim.bo[bufnr].filetype ~= "NvimTree"
      and vim.bo[bufnr].filetype ~= "qf"
      and not (vim.api.nvim_buf_get_name(bufnr)):match("^term://") then
      table.insert(bufs, bufnr)
    end
  end

  -- Sort: pinned first, then by order_override or bufnr
  table.sort(bufs, function(a, b)
    local pa, pb = pinned[a] and 1 or 0, pinned[b] and 1 or 0
    if pa ~= pb then return pa > pb end
    local oa = order_override[a] or a
    local ob = order_override[b] or b
    return oa < ob
  end)

  return bufs
end

local cached_bufs = {}

local section = {
  title = "Buffers",
  icon = "󰈚",
  update = function()
    cached_bufs = get_buffers()
  end,
  draw = function(ctx)
    cached_bufs = get_buffers()
    local lines, hl = {}, {}
    local current = vim.api.nvim_get_current_buf()

    for i, bufnr in ipairs(cached_bufs) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      local short = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
      local modified = vim.bo[bufnr].modified and " 󰛿" or ""
      local pin = pinned[bufnr] and " 󰐾" or ""
      local prefix = (bufnr == current) and "▸ " or "  "
      local line = prefix .. short .. modified .. pin

      table.insert(lines, line)
      local li = i - 1
      if bufnr == current then
        table.insert(hl, { "SidebarNvimBuffersActive", li, 0, -1 })
      end
    end

    if #lines == 0 then
      return { lines = { "  (no buffers)" }, hl = {} }
    end

    return { lines = lines, hl = hl }
  end,
  bindings = {
    ["e"] = function(line)
      local buf = cached_bufs[line + 1]
      if buf then
        vim.cmd("wincmd p")
        vim.api.nvim_set_current_buf(buf)
      end
    end,
    ["<CR>"] = function(line)
      local buf = cached_bufs[line + 1]
      if buf then
        vim.cmd("wincmd p")
        vim.api.nvim_set_current_buf(buf)
      end
    end,
    ["d"] = function(line)
      local buf = cached_bufs[line + 1]
      if buf then
        vim.api.nvim_command(":bwipeout " .. buf)
        pinned[buf] = nil
        order_override[buf] = nil
        require("sidebar-nvim").update()
      end
    end,
    ["p"] = function(line)
      local buf = cached_bufs[line + 1]
      if buf then
        pinned[buf] = true
        require("sidebar-nvim").update()
      end
    end,
    ["P"] = function(line)
      local buf = cached_bufs[line + 1]
      if buf then
        pinned[buf] = nil
        require("sidebar-nvim").update()
      end
    end,
    ["U"] = function(line)
      local idx = line + 1
      if idx > 1 then
        local buf = cached_bufs[idx]
        local prev = cached_bufs[idx - 1]
        if buf and prev then
          local bo = order_override[buf] or buf
          local po = order_override[prev] or prev
          order_override[buf] = po
          order_override[prev] = bo
          require("sidebar-nvim").update()
        end
      end
    end,
    ["D"] = function(line)
      local idx = line + 1
      if idx < #cached_bufs then
        local buf = cached_bufs[idx]
        local nxt = cached_bufs[idx + 1]
        if buf and nxt then
          local bo = order_override[buf] or buf
          local no = order_override[nxt] or nxt
          order_override[buf] = no
          order_override[nxt] = bo
          require("sidebar-nvim").update()
        end
      end
    end,
  },
}

return section
