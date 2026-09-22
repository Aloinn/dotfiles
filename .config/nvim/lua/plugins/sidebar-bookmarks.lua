-- Custom sidebar.nvim section: project-scoped marks from self_session
local cached_marks = {}

local function refresh_marks()
  local ok, ss = pcall(require, "self_session")
  if not ok then
    cached_marks = {}
    return
  end
  cached_marks = ss.marks_list()
end

local function jump(line)
  local m = cached_marks[line + 1]
  if not m then
    return
  end
  vim.cmd("wincmd p")
  require("self_session").jump_mark(m.key)
end

local section = {
  title = "Marks",
  icon = "󰃁",
  setup = function()
    refresh_marks()
  end,
  update = function()
    refresh_marks()
  end,
  draw = function()
    local lines = {}
    local hl = {}
    for i, m in ipairs(cached_marks) do
      -- Display: [key]: name -- or the mark's value (line text, else
      -- filename:line) when no name was given via M{key}
      local label
      if m.name and m.name ~= "" then
        label = m.name
      else
        local text = ""
        local buf = vim.fn.bufnr(m.path)
        if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
          text = vim.trim(vim.api.nvim_buf_get_lines(buf, m.line - 1, m.line, false)[1] or "")
        end
        label = text ~= "" and text
          or (vim.fn.fnamemodify(m.path, ":t") .. ":" .. m.line)
      end
      table.insert(lines, "  [" .. m.key .. "]: " .. label)
      -- Highlight the [key] prefix
      table.insert(hl, { "SidebarNvimSectionTitle", i - 1, 2, 5 })
    end
    if #lines == 0 then
      return { lines = { "  (no marks)" }, hl = {} }
    end
    return { lines = lines, hl = hl }
  end,
  bindings = {
    ["<CR>"] = jump,
    ["e"] = jump,
    ["d"] = function(line)
      local m = cached_marks[line + 1]
      if m then
        require("self_session").delete_mark(m.key)
        refresh_marks()
      end
    end,
  },
}

return section
