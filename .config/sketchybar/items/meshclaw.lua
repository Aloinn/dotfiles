-- MeshClaw unread notification badge.
-- Fed by ~/dotfiles/scripts/meshclaw-notify-listener.sh, which streams
-- ~/.meshclaw/notifications.jsonl from the dev desktop, bumps the unread
-- count file below, and fires the `meshclaw_notify` event.
-- Click the badge to reset the count.

local colors = require("colors")
local settings = require("settings")

local COUNT_FILE = os.getenv("HOME") .. "/.local/state/meshclaw/unread"

sbar.add("event", "meshclaw_notify")

-- Padding item required because of bracket
sbar.add("item", { width = 1 })

local meshclaw = sbar.add("item", "meshclaw", {
  label = {
    color = colors.white,
    font = { family = settings.font.numbers, style = "Bold", size = 18.0 },
    padding_left = 8,
    align = "right",
  },
  padding_left = 1,
  padding_right = 1,
  padding_top = 10,
  width = 40,
})

-- Double border using a single item bracket (same look as slack)
sbar.add("bracket", { meshclaw.name }, {
  background = {
    color = colors.transparent,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 7 })

local function refresh()
  sbar.exec("cat '" .. COUNT_FILE .. "' 2>/dev/null", function(value)
    local count = tonumber((value or ""):match("%d+")) or 0
    local unread = count > 0
    meshclaw:set({
      background = { color = unread and colors.green or colors.bar.bg },
      label = {
        string = unread and tostring(count) or "_",
        -- dark text on green for contrast; white on the plain bar
        color = unread and colors.black or colors.white,
      },
    })
  end)
end

meshclaw:subscribe({ "forced", "system_woke", "meshclaw_notify" }, refresh)

meshclaw:subscribe("mouse.clicked", function(_)
  sbar.exec("mkdir -p \"$(dirname '" .. COUNT_FILE .. "')\" && echo 0 > '" .. COUNT_FILE .. "'", refresh)
end)
