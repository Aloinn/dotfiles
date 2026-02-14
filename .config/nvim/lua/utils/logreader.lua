local M = {}

-- Highlight groups
vim.cmd([[highlight LogTime guifg=#8BE9FD]])
vim.cmd([[highlight LogLevelInfo guifg=#50FA7B]])
vim.cmd([[highlight LogLevelWarn guifg=#F1FA8C]])
vim.cmd([[highlight LogLevelError guifg=#FF5555]])
vim.cmd([[highlight LogKey guifg=#BD93F9]])
vim.cmd([[highlight LogValue guifg=#F8F8F2]])

-- Utility: split by delimiter ignoring braces
local function split_top_level(str, delimiter)
  local result = {}
  local current = ""
  local depth = 0
  for i = 1, #str do
    local char = str:sub(i,i)
    if char == "{" then depth = depth + 1
    elseif char == "}" then depth = depth - 1 end
    if char == delimiter and depth == 0 then
      table.insert(result, current)
      current = ""
    else
      current = current .. char
    end
  end
  if current ~= "" then table.insert(result, current) end
  return result
end

-- Parse Object{key=value; key=value}
local function parse_object(str)
  local obj_type, body = str:match("^(%w+)%{(.+)%}$")
  if not obj_type then return nil end
  local fields = {}
  local pairs = split_top_level(body, ";")
  for _, pair in ipairs(pairs) do
    local k,v = pair:match("([^=]+)=([^=]+)")
    if k and v then
      table.insert(fields, obj_type.."."..vim.trim(k).." = "..vim.trim(v))
    end
  end
  return fields
end

-- Parse main log line
local function parse_main_log(line)
  local ts, level, thread, component, method, rest = line:match(
    "^(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d,%d+)%s+%[(%w+)%s*%]%s+%((.-)%)%s+%-%s+(.-)%s+%-%s+(.-)%s+%-%s+(.*)"
  )
  if not ts then return nil end
  local message, attrs = rest:match("^(.-);%s*(.*)$")
  return {
    timestamp = ts,
    level = level,
    thread = thread,
    component = component,
    method = method,
    message = message or rest,
    attributes = attrs or ""
  }
end

-- Parse attributes key: value
local function parse_attributes(attr_string)
  local results = {}
  local parts = split_top_level(attr_string, ",")
  for _, part in ipairs(parts) do
    local key,value = part:match("([^:]+):(.+)")
    if key and value then
      key = vim.trim(key)
      value = vim.trim(value)
      local obj = parse_object(value)
      if obj then
        for _, line in ipairs(obj) do
          local sub = line:match("^%w+%.(.+)")
          table.insert(results, key.."."..sub)
        end
      else
        table.insert(results, key.." = "..value)
      end
    end
  end
  return results
end

-- Global state
local popup_buf, popup_win

-- Build content and highlights
local function build_content_and_highlights(line)
  local content = {}
  local highlights = {}

  local log = parse_main_log(line)

  if not log then
    table.insert(content, "Line does not match log format:")
    table.insert(content, line)
    return content, highlights
  end

  -- Header
  table.insert(content, "time      : "..log.timestamp)
  table.insert(content, "level     : "..log.level)
  table.insert(content, "thread    : "..log.thread)
  table.insert(content, "component : "..log.component)
  table.insert(content, "method    : "..log.method)
  table.insert(content, "message   : "..log.message)

  -- Header highlights
  table.insert(highlights, { line=1, start_col=12, end_col=#log.timestamp+12, group="LogTime" })
  local level_group = "LogLevelInfo"
  if log.level == "WARN" then level_group="LogLevelWarn"
  elseif log.level=="ERROR" then level_group="LogLevelError" end
  table.insert(highlights, { line=2, start_col=12, end_col=#log.level+12, group=level_group })

  -- Attributes
  if log.attributes~="" then
    table.insert(content,"-------------------------")
    local attrs = parse_attributes(log.attributes)
    local line_idx = #content - #attrs + 1
    for _, attr_line in ipairs(attrs) do
      table.insert(content, attr_line)
      local key,value = attr_line:match("([^=]+)=([^\n]+)")
      if key and value then
        table.insert(highlights,{ line=line_idx, start_col=0, end_col=#key, group="LogKey" })
        table.insert(highlights,{ line=line_idx, start_col=#key+3, end_col=#key+3+#value, group="LogValue" })
      end
      line_idx = line_idx + 1
    end
  end

  return content, highlights
end

-- ==============================
-- Show/update popup
-- ==============================
local function update_popup()
    local line = vim.api.nvim_get_current_line()
  local content, highlights = build_content_and_highlights(line)
  if not content or #content == 0 then return end

  if not popup_buf or not vim.api.nvim_buf_is_valid(popup_buf) then
    popup_buf = vim.api.nvim_create_buf(false, true)
  end
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, content)

  local width = 0
  for _, l in ipairs(content) do width = math.max(width, #l) end
  local height = #content

  -- Popup floats relative to cursor
  local row = 1  -- below cursor; use -height for above

  if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
    popup_win = vim.api.nvim_open_win(popup_buf, false, {
      relative = "cursor",
      row = row,
      col = row,
      width = width + 2,
      height = height,
      style = "minimal",
      border = "rounded",
      focusable = false,
    })
  else
    -- Update position and size
    vim.api.nvim_win_set_height(popup_win, height)
    vim.api.nvim_win_set_width(popup_win, width + 2)
    vim.api.nvim_win_set_config(popup_win, { relative = "cursor", row = row, col = row })
  end

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(popup_buf, -1, 0, -1)
  -- for _, hl in ipairs(highlights) do
    -- vim.api.nvim_buf_add_highlight(popup_buf, -1, hl.group, hl.line - 1, hl.start_col, hl.end_col)
  -- end
end
-- ==============================
-- Public entry
-- ==============================
function M.start_auto_popup()
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    pattern = "*",
    callback = update_popup,
  })
end
M.update_popup = update_popup

vim.api.nvim_create_user_command("LogPopup", function()
  M.start_auto_popup()
  print("Live log popup started for this buffer!")
end, { desc = "Start live log popup for current buffer" })
return M

