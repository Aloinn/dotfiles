
local M = {}

-- function M.show_parsed_line()
--   -- get current log line
--   local line = vim.api.nvim_get_current_line()
--   -- split by commas
--   local parts = vim.split(line, ",")
--
--   -- create a scratch buffer
--   local buf = vim.api.nvim_create_buf(false, true)
--
--   -- format parts nicely
--   local content = {}
--   for i, p in ipairs(parts) do
--     content[i] = string.format("%d: %s", i, vim.trim(p))
--   end
--
--   vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
--
--   -- popup window
--   local width  = math.max(unpack(vim.tbl_map(function(s) return #s end, content))) + 4
--   local height = #content
--
--   local win = vim.api.nvim_open_win(buf, true, {
--     relative = "cursor",
--     row = 1,
--     col = 0,
--     width = width,
--     height = height,
--     style = "minimal",
--     border = "rounded"
--   })
--
--   -- close on <esc>
--   vim.api.nvim_buf_set_keymap(buf, "n", "<esc>", "<cmd>close<CR>", { silent = true })
-- end

-- split by delimiter but ignore inside {}
local function split_top_level(str, delimiter)
  local result = {}
  local current = ""
  local depth = 0

  for i = 1, #str do
    local char = str:sub(i, i)

    if char == "{" then
      depth = depth + 1
    elseif char == "}" then
      depth = depth - 1
    end

    if char == delimiter and depth == 0 then
      table.insert(result, current)
      current = ""
    else
      current = current .. char
    end
  end

  if current ~= "" then
    table.insert(result, current)
  end

  return result
end

local M = {}

-- ==============================
-- Utility: split delimiter ignoring {}
-- ==============================
local function split_top_level(str, delimiter)
  local result = {}
  local current = ""
  local depth = 0

  for i = 1, #str do
    local char = str:sub(i, i)

    if char == "{" then
      depth = depth + 1
    elseif char == "}" then
      depth = depth - 1
    end

    if char == delimiter and depth == 0 then
      table.insert(result, current)
      current = ""
    else
      current = current .. char
    end
  end

  if current ~= "" then
    table.insert(result, current)
  end

  return result
end

-- ==============================
-- Parse Object{a=1; b=2}
-- ==============================
local function parse_object(str)
  local obj_type, body = str:match("^(%w+)%{(.+)%}$")
  if not obj_type then return nil end

  local fields = {}
  local pairs = split_top_level(body, ";")

  for _, pair in ipairs(pairs) do
    local k, v = pair:match("([^=]+)=([^=]+)")
    if k and v then
      table.insert(fields, obj_type .. "." .. vim.trim(k) .. " = " .. vim.trim(v))
    end
  end

  return fields
end

-- ==============================
-- Parse main structured log line
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
local function parse_attributes(attr_string)
  local results = {}
  local parts = split_top_level(attr_string, ",")

  for _, part in ipairs(parts) do
    local key, value = part:match("([^:]+):(.+)")
    if key and value then
      key = vim.trim(key)
      value = vim.trim(value)

      local obj = parse_object(value)

      if obj then
        for _, line in ipairs(obj) do
          local sub = line:match("^%w+%.(.+)")
          table.insert(results, key .. "." .. sub)
        end
      else
        table.insert(results, key .. " = " .. value)
      end
    end
  end

  return results
end

-- ==============================
-- Create popup window
-- ==============================
local function show_popup(lines)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end

  local height = #lines

  vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width + 2,
    height = height,
    style = "minimal",
    border = "rounded"
  })

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
end

-- ==============================
-- Public entry function
-- ==============================
function M.show_parsed_line()
  local line = vim.api.nvim_get_current_line()
  local content = {}

  local log = parse_main_log(line)

  if not log then
    table.insert(content, "Unrecognized log format")
    show_popup(content)
    return
  end

  table.insert(content, "time      : " .. log.timestamp)
  table.insert(content, "level     : " .. log.level)
  table.insert(content, "thread    : " .. log.thread)
  table.insert(content, "component : " .. log.component)
  table.insert(content, "method    : " .. log.method)
  table.insert(content, "message   : " .. log.message)

  if log.attributes ~= "" then
    table.insert(content, "-------------------------")
    local attrs = parse_attributes(log.attributes)
    vim.list_extend(content, attrs)
  end

  show_popup(content)
end

vim.keymap.set("n", "<leader>lll", function()
 M.show_parsed_line()
end, { desc = "Parse log line" })

return M

-- parse Object{a=1; b=2}
-- 2026-02-13 20:50:58,417 [INFO ] (replication-message-handler30ae1700-f195-4324-9538-0daa2ee30265-172.16.105.217data4-15) - MasterContext - memberState - Gather State: member reports that it has a newer membership version (we're both still members); tableId: 292924be-6970-43b6-80eb-f3c43fc1247c, partitionId: 62272c46-84dc-40ca-b39c-19146b3a3fb1, bucketName: bb_replica_19219, tableName: test_table_1752333552598, isJournalBacked: false, selfNodeId: 30ae1700-f195-4324-9538-0daa2ee30265-172.16.105.217, member: Member:{partitionId=62272c46-84dc-40ca-b39c-19146b3a3fb1; nodeInfo=N:693ad3ee-37f2-4621-b30f-92ef275db5f2-10.94.184.22:H:10.94.184.22:P:45678:D:IAD6; state=full; joinLSN=LSN:{0, 0, 0}; membershipChangeVersion=0; 1stAvailLSN=unknown; nonPrivileged=false; role=FullSN}, our membership version: 87, our membership version LSN: LSN:{297, 9674498, 301}, their membership version: 89, their membership version LSN: LSN:{305, 10101651, 309}, our latest LSN: LSN:{305, 10101526, 309}, their latest LSN: LSN:{305, 10101651, 309}

