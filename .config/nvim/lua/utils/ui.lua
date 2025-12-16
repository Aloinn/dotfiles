local M = {}
function M.get_icon(icon_name, fallback_to_empty_string)
  -- guard clause
  if fallback_to_empty_string and vim.g.fallback_icons_enabled then return "" end

  -- get icon_pack
  local icon_pack = (vim.g.fallback_icons_enabled and "fallback_icons") or "icons"

  -- cache icon_pack into M
  if not M[icon_pack] then -- only if not cached already.
    if icon_pack == "icons" then
      M.icons = require("utils.icons.icons")
    elseif icon_pack =="fallback_icons" then
      M.fallback_icons = require("utils.icons.fallback_icons")
    end
  end

  -- return specified icon
  local icon = M[icon_pack] and M[icon_pack][icon_name]
  return icon
end

return M
