-- Custom sidebar.nvim section: marks.nvim integration
local cached_marks = {}

local function refresh_marks()
  local items = {}
  -- Find the main editing buffer (skip sidebar window)
  local bufnr = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "SidebarNvim" and vim.bo[buf].buflisted then
      bufnr = buf
      break
    end
  end
  if not bufnr then return end

  -- Read from marks.nvim internal state (immediately up-to-date)
  local ok, marks_mod = pcall(require, "marks")
  if ok and marks_mod.mark_state and marks_mod.mark_state.buffers[bufnr] then
    for mark, data in pairs(marks_mod.mark_state.buffers[bufnr].placed_marks) do
      if mark:match("[a-z]") then
        local text = vim.api.nvim_buf_get_lines(bufnr, data.line - 1, data.line, false)[1] or ""
        table.insert(items, { mark = mark, line = data.line, bufnr = bufnr, text = vim.trim(text) })
      end
    end
  end

  -- Uppercase marks (global) — these are always in getmarklist()
  for _, data in ipairs(vim.fn.getmarklist()) do
    local mark = data.mark:sub(2, 2)
    if mark:match("[A-Z]") then
      local buf = data.pos[1]
      local line = data.pos[2]
      local text = ""
      if vim.api.nvim_buf_is_loaded(buf) then
        text = (vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or "")
      end
      table.insert(items, { mark = mark, line = line, bufnr = buf, text = vim.trim(text) })
    end
  end

  table.sort(items, function(a, b) return a.mark < b.mark end)
  cached_marks = items
end

local section = {
  title = "Marks",
  icon = "󰃁",
  setup = function()
    refresh_marks()
    -- Wrap marks.nvim functions to trigger immediate sidebar refresh
    local ok, marks_mod = pcall(require, "marks")
    if ok then
      local sbn = require("sidebar-nvim")
      for _, fn in ipairs({ "set", "set_next", "delete", "delete_line", "delete_buf" }) do
        local orig = marks_mod[fn]
        if orig then
          marks_mod[fn] = function(...)
            orig(...)
            refresh_marks()
            sbn.update()
          end
        end
      end
    end
  end,
  update = function() refresh_marks() end,
  draw = function()
    local lines = {}
    for _, m in ipairs(cached_marks) do
      local preview = m.text ~= "" and m.text or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(m.bufnr), ":t")
      table.insert(lines, "  " .. m.mark .. ":" .. m.line .. " " .. preview)
    end
    if #lines == 0 then
      return { lines = { "  (no marks)" }, hl = {} }
    end
    return { lines = lines, hl = {} }
  end,
  bindings = {
    ["<CR>"] = function(line)
      local m = cached_marks[line + 1]
      if m then
        vim.cmd("wincmd p")
        if m.bufnr ~= vim.api.nvim_get_current_buf() then
          vim.cmd("buffer " .. m.bufnr)
        end
        vim.api.nvim_win_set_cursor(0, { m.line, 0 })
      end
    end,
    ["e"] = function(line)
      local m = cached_marks[line + 1]
      if m then
        vim.cmd("wincmd p")
        if m.bufnr ~= vim.api.nvim_get_current_buf() then
          vim.cmd("buffer " .. m.bufnr)
        end
        vim.api.nvim_win_set_cursor(0, { m.line, 0 })
      end
    end,
    ["d"] = function(line)
      local m = cached_marks[line + 1]
      if m then
        vim.cmd("delmark " .. m.mark)
        local ok, marks_mod = pcall(require, "marks")
        if ok then marks_mod.mark_state:delete_mark(m.mark, false) end
        refresh_marks()
      end
    end,
  },
}

return section
