require("items.apple")
require("items.slack")

-- MeshClaw badge only on my Mac (the listener that feeds it runs there).
local function short_hostname()
  local handle = io.popen("hostname -s 2>/dev/null")
  if not handle then return "" end
  local name = handle:read("*l") or ""
  handle:close()
  return name
end

if short_hostname() == "6cb133a1d2fd" then
  require("items.meshclaw")
end

require("items.menus")
require("items.spaces")
require("items.calendar")
require("items.widgets")
require("items.media")
