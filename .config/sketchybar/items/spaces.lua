local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local notch = require("helpers.notch")

local spaces = {}

-- Estimated pixel width per space item (icon paddings + app-icon label);
-- refreshed on space_windows_change so notch wrapping stays accurate.
local space_widths = {}
local space_exists = {}

-- Base width: icon padding_left(15) + digit(~10) + icon padding_right(8)
-- + label padding_right(20) + bracket pad
local SPACE_BASE_W = 55
local APP_ICON_W = 24

-- Re-lay out all space items: walk the left stack, and give the first
-- space that would collide with the notch enough padding to jump it.
local function relayout_spaces()
  if notch.width == 0 then return end
  sbar.exec("yabai -m query --spaces", function(yabai_spaces)
    if type(yabai_spaces) ~= "table" then return end
    for i = 1, 20 do space_exists[i] = false end
    for _, s in ipairs(yabai_spaces) do
      if s.index and s.index <= 20 then space_exists[s.index] = true end
    end

    -- Spaces swap with the menu row, so they start right after the fixed
    -- left items (apple + slack + pads).
    local x = notch.left_fixed_width
    for i = 1, 20, 1 do
      if space_exists[i] then
        local w = space_widths[i] or SPACE_BASE_W
        local jump = notch.jump(x, w)
        spaces[i]:set({ padding_left = 1 + jump })
        x = x + w + jump + settings.group_paddings
      end
    end
  end)
end

for i = 1, 20, 1 do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers },
      string = i,
      y_offset=-2,
      padding_left = 15,
      padding_right = 8,
      color = colors.white,
      highlight_color = colors.white,
    },
    label = {
      padding_right = 20,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:20.0",
      y_offset = -3,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.bg1,
      border_width = 0,
      height = 40,
      border_color = colors.red,
    },
    popup = { background = { border_width = 0, border_color = colors.black } }
  })

  spaces[i] = space
  space_widths[i] = SPACE_BASE_W
  space_exists[i] = false

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
    }
  })

  -- Padding space
  sbar.add("space", "space.padding." .. i, {
    space = i,
    script = "",
    width = settings.group_paddings,
  })

  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
    padding_left= 5,
    padding_right= 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        -- scale = 0.2
      }
    }
  })

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    local color = selected and colors.grey or colors.bg2
    space:set({
      icon = { highlight = selected, },
      label = { highlight = selected },
      background = { 
        color = selected and colors.cyan or colors.bg2,
        border_color = selected and colors.red or colors.bg2 }
    })
    space_bracket:set({
      background = { border_color = selected and colors.grey or colors.bg2 }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      sbar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

space_window_observer:subscribe("space_change", function(env)
  relayout_spaces()
end)

local spaces_indicator = sbar.add("item", {
  padding_left = -3,
  padding_right = 0,
  icon = {
    padding_left = 8,
    padding_right = 9,
    color = colors.grey,
    string = icons.switch.on,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
    string = "Spaces",
    color = colors.bg1,
  },
  background = {
    color = colors.with_alpha(colors.grey, 0.0),
    border_color = colors.with_alpha(colors.bg1, 0.0),
  }
})

space_window_observer:subscribe("space_windows_change", function(env)
  local icon_line = ""
  local no_app = true
  local app_count = 0
  for app, count in pairs(env.INFO.apps) do
    no_app = false
    app_count = app_count + 1
    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons["default"] or lookup)
    icon_line = icon_line .. " " .. icon
  end

  if (no_app) then
    icon_line = " —"
    app_count = 1
  end
  space_widths[env.INFO.space] = SPACE_BASE_W + app_count * APP_ICON_W
  sbar.animate("tanh", 10, function()
    spaces[env.INFO.space]:set({ label = icon_line })
  end)
  relayout_spaces()
end)

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 0.0 },
        border_color = { alpha = 0.0 },
      },
      icon = { color = colors.grey },
      label = { width = 0, }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)

-- Initial notch-aware layout at startup
relayout_spaces()
