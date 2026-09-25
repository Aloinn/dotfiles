-- Notch detection + wrap helpers.
--
-- Detects the camera notch on the built-in display (macOS 12+) via the
-- NSScreen safe-area APIs, then wraps left-stacked items around the
-- notch using their REAL rendered bounding rects (queried back from
-- sketchybar) -- no font-width guessing.

local M = {
  width = 0,        -- notch width in points (0 = no notch detected)
  screen_width = 0, -- width of the notched display in points
  display = 1,      -- display number carrying the notch
  margin = 12,      -- safety gap (pt) on each side of the notch
}

-- JXA one-liner: find the screen with a top safe-area inset (the notch
-- display) and print "<notch_width> <screen_width> <display_index>".
local jxa = [[osascript -l JavaScript -e '
ObjC.import("AppKit");
let out = "0 0 1";
const screens = $.NSScreen.screens;
for (let i = 0; i < screens.count; i++) {
  const s = screens.objectAtIndex(i);
  if (s.safeAreaInsets.top > 0) {
    const f = s.frame.size.width;
    const tl = s.auxiliaryTopLeftArea.size.width;
    const tr = s.auxiliaryTopRightArea.size.width;
    out = String(f - tl - tr) + " " + String(f) + " " + String(i + 1);
    break;
  }
}
out' 2>/dev/null]]

local handle = io.popen(jxa)
if handle then
  local result = handle:read("*a") or ""
  handle:close()
  local nw, sw, disp = result:match("([%d%.]+)%s+([%d%.]+)%s+(%d+)")
  M.width = tonumber(nw) or 0
  M.screen_width = tonumber(sw) or 0
  M.display = tonumber(disp) or 1
end

-- x coordinate where the keep-out zone begins / ends
function M.left_edge()
  return (M.screen_width - M.width) / 2 - M.margin
end

function M.right_edge()
  return (M.screen_width + M.width) / 2 + M.margin
end

-- Extract the bounding rect of `item` on the notched display.
-- Returns x, w or nil when the item is not drawn / has no rect.
local function rect_of(item)
  local ok, info = pcall(function() return item:query() end)
  if not ok or type(info) ~= "table" then return nil end
  if info.geometry and info.geometry.drawing == "off" then return nil end
  local rects = info.bounding_rects
  if type(rects) ~= "table" then return nil end
  local rect = rects["display-" .. M.display]
  if not rect then
    local _, first = next(rects)
    rect = first
  end
  if type(rect) ~= "table" or type(rect.origin) ~= "table" then return nil end
  local x = tonumber(rect.origin[1])
  local w = tonumber(rect.size and rect.size[1]) or 0
  if not x then return nil end
  return x, w
end

-- Wrap a left-stacked row of items around the notch.
--
-- `entries` is an ordered (left-to-right) list of { item = <sbar item>,
-- base = <normal padding_left> }. All items are first reset to their
-- base padding (clearing stale jumps), then -- once the bar has
-- re-rendered -- their real bounding rects are queried and the FIRST
-- item that intersects the keep-out zone is padded past the notch's
-- right edge. Everything after it shifts right with it.
--
-- `on_done(wrapped)` is called with whether a wrap was applied.
function M.wrap(entries, on_done)
  if M.width == 0 then
    if on_done then on_done(false) end
    return
  end

  for _, e in ipairs(entries) do
    e.item:set({ padding_left = e.base })
  end

  sbar.delay(0.15, function()
    local le, re = M.left_edge(), M.right_edge()
    local wrapped = false
    for _, e in ipairs(entries) do
      local x, w = rect_of(e.item)
      if x and x < re and (x + w) > le then
        e.item:set({ padding_left = e.base + (re - x) })
        wrapped = true
        break
      end
    end
    if on_done then on_done(wrapped) end
  end)
end

return M
