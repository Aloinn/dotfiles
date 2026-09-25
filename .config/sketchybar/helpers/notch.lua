-- Notch detection + wrap helpers.
--
-- Detects the camera notch on the built-in display (macOS 12+) via the
-- NSScreen safe-area APIs and exposes geometry helpers so left-stacked
-- items can "jump" over the notch instead of rendering under it.
--
-- Tunables:
--   margin           extra safety gap (pt) on each side of the notch
--   left_fixed_width estimated width (pt) of the fixed items to the left
--                    of menus/spaces (apple logo + slack + brackets/pads)

local M = {
  width = 0,        -- notch width in points (0 = no notch detected)
  screen_width = 0, -- width of the notched display in points
  margin = 12,
  left_fixed_width = 110,
}

-- JXA one-liner: find the screen with a top safe-area inset (the notch
-- display) and print "<notch_width> <screen_width>".
local jxa = [[osascript -l JavaScript -e '
ObjC.import("AppKit");
let out = "0 0";
const screens = $.NSScreen.screens;
for (let i = 0; i < screens.count; i++) {
  const s = screens.objectAtIndex(i);
  if (s.safeAreaInsets.top > 0) {
    const f = s.frame.size.width;
    const tl = s.auxiliaryTopLeftArea.size.width;
    const tr = s.auxiliaryTopRightArea.size.width;
    out = String(f - tl - tr) + " " + String(f);
    break;
  }
}
out' 2>/dev/null]]

local handle = io.popen(jxa)
if handle then
  local result = handle:read("*a") or ""
  handle:close()
  local nw, sw = result:match("([%d%.]+)%s+([%d%.]+)")
  M.width = tonumber(nw) or 0
  M.screen_width = tonumber(sw) or 0
end

-- x coordinate where the keep-out zone begins / ends
function M.left_edge()
  return (M.screen_width - M.width) / 2 - M.margin
end

function M.right_edge()
  return (M.screen_width + M.width) / 2 + M.margin
end

-- Given a left-stack cursor position `x` and the width `w` of the next
-- item, return the extra left padding needed to jump the item past the
-- notch (0 if it fits before the notch or is already past it).
function M.jump(x, w)
  if M.width == 0 then return 0 end
  local le, re = M.left_edge(), M.right_edge()
  if x < re and (x + w) > le then
    return re - x
  end
  return 0
end

-- Rough width estimate (pt) for a text label incl. its paddings.
function M.estimate_text_width(text, heavy)
  local char_px = heavy and 8.5 or 8.0
  return 12 + (#text * char_px)
end

return M
