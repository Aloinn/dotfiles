local M = {}

-- ==============================
-- Highlight groups
-- ==============================
vim.cmd([[highlight LogKey guifg=#DBBC7F]])

local popup_buf, popup_win
-- ==============================
-- Namespace for modern highlighting
-- ==============================
local ns_id = vim.api.nvim_create_namespace("log_popup")

-- ==============================
-- Utility: split delimiter ignoring braces
-- ==============================
local function split_top_level(str, delimiter)
  local result = {}
  local current = ""
  local depth = 0
  for i = 1, #str do
    local char = str:sub(i,i)
    if char == "{" or char == "[" then depth = depth + 1
    elseif char == "}" or char == "]" then depth = depth - 1 end
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
-- Recursive parser for Object{...}, splitting on ';' inside braces
-- Recursively parse values with {} or [] into indented lines
--
-- Split a string on ';' only when inside braces
-- -- Simple braces parser: newline after '{', indent inside braces including '}'
-- local function parse_braces_multiline(val, indent=0)
--   val = vim.trim(val)
--   local result = {}
--   local current = ""
--   local indent_level = 0
--
--   for i = 1, #val do
--     local c = val:sub(i,i)
--     current = current .. c
--     if c == "{" or c == "[" then
--       table.insert(result, string.rep(" ", indent_level*2) .. vim.trim(current)) -- new line after {
--       indent_level = indent_level + 1
--       current = ""
--     elseif c == "}" or c == "]" then
--       -- if current ~= "" then
--       table.insert(result, string.rep(" ", indent_level*2) .. vim.trim(current))
--       current = ""
--       indent_level = indent_level - 1
--     elseif (c == ";" or c == ",") and indent_level > 0 then
--       if current ~= ";" then
--           table.insert(result, string.rep(" ", indent_level*2) .. vim.trim(current))
--       end
--       current = ""
--     else
--     end
--   end
--
--   if current ~= "" then
--     table.insert(result, string.rep(" ", indent_level*2) .. vim.trim(current))
--   end
--
--   return result
-- end
-- Recursive parser for braces/brackets using Lua patterns
local function parse_braces_regex(val, indent)
  indent = indent or 0
  val = vim.trim(val)
  local result = {}

  -- find first {…} or […] block
  local pre, block, post = val:match("^(.-)(%b{})(.*)$")
  if not pre then
    pre, block, post = val:match("^(.-)(%b%[%])(.*)$")
  end
  if block and #block <= 20 then
        -- add anything before the block
    if pre:match("%S") then
      for part in pre:gmatch("([^;,]+)[;,]?") do
        if part:match("%S") then
          table.insert(result, string.rep(" ", indent*2) .. vim.trim(part))
        end
      end

      -- table.insert(result, string.rep(" ", indent*2) .. vim.trim(pre))
    end
    table.insert(result, string.rep(" ", (indent+1)*2) .. block)
    local post_lines = parse_braces_regex(post, indent)
    for _, line in ipairs(post_lines) do
      table.insert(result, line)
    end
    return result
  end
  if block then
    -- add anything before the block
    if pre:match("%S") then
      for part in pre:gmatch("([^;,]+)[;,]?") do
        if part:match("%S") then
          table.insert(result, string.rep(" ", indent*2) .. vim.trim(part))
        end
      end

      -- table.insert(result, string.rep(" ", indent*2) .. vim.trim(pre))
    end

    -- remove outer braces/brackets
    local inner = block:sub(2, -2)
    local open_char, close_char = block:sub(1,1), block:sub(-1,-1)

    -- new line for opening
    table.insert(result, string.rep(" ", indent*2) .. open_char)

    -- recursively parse inner content
    local inner_lines = parse_braces_regex(inner, indent + 1)
    for _, line in ipairs(inner_lines) do
      table.insert(result, line)
    end

    -- closing line
    table.insert(result, string.rep(" ", indent*2) .. close_char)

    -- recursively parse the rest
    local post_lines = parse_braces_regex(post, indent)
    for _, line in ipairs(post_lines) do
      table.insert(result, line)
    end

  else
    -- no block → split by ; or , for nicer formatting
    -- for part in val:gmatch("([^;,]+)[;,]?") do
    --   if part:match("%S") then
    --     table.insert(result, string.rep(" ", indent*2) .. vim.trim(part))
    --   end
    -- end
    local sep_pattern = (indent == 0) and "([^;]+);?" or "([^;,]+)[;,]?"
    for part in val:gmatch(sep_pattern) do
      if part:match("%S") then
        table.insert(result, string.rep(" ", indent*2) .. vim.trim(part))
      end
    end

  end

  return result
end


-- Focus the popup window if it exists
function M.focus_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_set_current_win(popup_win)
  else
    print("Popup window not available")
  end
end


-- ==============================
-- Parse main log line
-- ==============================
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

-- ==============================
-- Parse attributes key: value
-- ==============================
-- local function parse_attributes(attr_string)
--   local results = {}
--   local parts = split_top_level(attr_string, ",")
--
--   for _, part in ipairs(parts) do
--     local key, value = part:match("([^:]+):(.+)")
--     if key and value then
--       key = vim.trim(key)
--       value = vim.trim(value)
--       if value:match("{") or value:match("%[") then
--         lines = parse_braces_multiline(value)
--         -- prepend key only to first line
--         lines[1] = key .. " = " .. lines[1]:gsub("^%s+", "")
--         for _, l in ipairs(lines) do table.insert(results, l) end
--       else
--         table.insert(results, key .. " = " .. value)
--       end
--     end
--   end
--
--   return results
-- end

local function parse_attributes(attr_string)
  local results = {}

  -- Split top-level attributes by comma (not inside braces)
  local parts = split_top_level(attr_string, ",")

  for _, part in ipairs(parts) do
    local key, value = part:match("([^:]+):(.+)")
    if key and value then
      key = vim.trim(key)
      value = vim.trim(value)

      local lines = {}

        -- lines = { key .. " = " .. value }
      --
      -- -- check for braces and always parse recursively
      if value:match("{") or value:match("%[") then
        -- parse any object recursively
        lines = parse_braces_regex(value)
        -- prepend key to the first line
        lines[1] = key .. " = " .. lines[1]:gsub("^%s+", "")
      else
        -- no braces → single line
        lines = { key .. " = " .. value }
      end

      -- add lines to results
      for _, l in ipairs(lines) do
        table.insert(results, l)
      end
    end
  end

  return results
end

-- ==============================
-- Build content (text only)
-- ==============================
local function build_content(line)
  local content = {}
  local log = parse_main_log(line)

  if not log then
    table.insert(content, "Line does not match log format:")
    table.insert(content, line)
    return content
  end

  -- Header lines (no color)
  table.insert(content, log.timestamp)
  table.insert(content, "("..log.thread..")")
  table.insert(content, "["..log.level.."] "..log.component.." - "..log.method)
  table.insert(content, log.message)

  -- Attributes
  if log.attributes ~= "" then
    table.insert(content,"-------------------------")
    local attrs = parse_attributes(log.attributes)
    for _, attr_line in ipairs(attrs) do
      table.insert(content, attr_line)
    end
  end

  return content
end

-- ==============================
-- Highlight attribute keys using vim.hl.range
-- ==============================
local function highlight_attributes(content)
  vim.api.nvim_buf_clear_namespace(popup_buf, ns_id, 0, -1)

  local attr_start = false
  local start_line = 1
  for idx, line in ipairs(content) do
    if line:match("^%-+$") then
      attr_start = true
      start_line = idx + 1
    elseif attr_start then
      local key,_ = line:match("([^=]+)=")
      if key then
        local s_col = 0
        local e_col = #key
        vim.hl.range(popup_buf, ns_id, "LogKey",
          {idx-1, s_col}, {idx-1, e_col},
          {priority = 100}
        )
      end
    end
  end
end

-- Recursive parser for Object{...}


function M.set_popup_keymaps()
  if popup_buf and vim.api.nvim_buf_is_valid(popup_buf) then
    -- Q to close the popup
    vim.api.nvim_buf_set_keymap(
      popup_buf,
      "n",
      "q",
      "<cmd>q<CR>",
      { noremap = true, silent = true }
    )
  end
end
-- ==============================
-- Show or update popup
-- ==============================
local function update_popup()
  local line = vim.api.nvim_get_current_line()
  local content = build_content(line)
  if not content or #content == 0 then return end

  if not popup_buf or not vim.api.nvim_buf_is_valid(popup_buf) then
    popup_buf = vim.api.nvim_create_buf(false,true)
  end
  vim.api.nvim_buf_set_lines(popup_buf,0,-1,false,content)

  local width = 0
  for _, l in ipairs(content) do width = math.max(width,#l) end
  local height = #content

  if not popup_win or not vim.api.nvim_win_is_valid(popup_win) then
    popup_win = vim.api.nvim_open_win(popup_buf,false,{
      relative="cursor",
      row=1, col=1,
      width=width+2, height=height,
      style="minimal",
      border="rounded",
      focusable=false
    })
      M.set_popup_keymaps()
  else
    vim.api.nvim_win_set_height(popup_win,height)
    vim.api.nvim_win_set_width(popup_win,width+2)
    vim.api.nvim_win_set_config(popup_win,{ relative="cursor", row=1, col=1 })
  end

  -- Apply attribute key highlights
  highlight_attributes(content)
end

-- ==============================
-- Expose update_popup for manual testing
-- ==============================
M.update_popup = update_popup

-- ==============================
-- Start live popup on cursor move
-- ==============================
local bufnr = vim.api.nvim_get_current_buf()
local popup_autocmd_id = nil
function M.start_auto_popup()
  popup_autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved","CursorMovedI" },{
    buffer = bufnr, 
    callback=update_popup,
  })
  vim.keymap.set("n", ">", function()
    M.focus_popup()
  end, { desc = "Toggle log reader" })
  update_popup()
end

function M.close_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
    popup_win = nil
  end
end
function M.disable_popup()
  if popup_autocmd_id then
    vim.api.nvim_del_autocmd(popup_autocmd_id)
    popup_autocmd_id = nil
  end
  -- also close popup window if open
  M.close_popup()
end
function M.toggle_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    M.disable_popup()
  else
    M.start_auto_popup()
  end
end


-- ==============================
-- Optional command to start popup
-- ==============================
-- -- You can put this at the bottom of your file
vim.api.nvim_create_user_command("LogPopupEnter", function()
  M.focus_popup()
  -- M.update_popup()-- require("custom.log_popup").update_popup()
end, { desc="Start live log popup" })

vim.api.nvim_create_user_command("LogPopup", function()
  M.start_auto_popup()
  -- M.update_popup()-- require("custom.log_popup").update_popup()
  print("Live log popup started!")
end, { desc="Start live log popup" })
vim.keymap.set("n", "<leader>lll", function()
  M.toggle_popup()
end, { desc = "Toggle log reader" })

return M

