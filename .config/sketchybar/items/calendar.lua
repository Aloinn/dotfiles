local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.white,
    -- padding_left = 8,
    font = {
      style = settings.font.style_map["Regular"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 8,
    -- width = 69,
    y_offset = -1,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.cyan,
  },
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = ''
  , label = os.date("%I:%M %p") })
end)

-- cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
--   cal:set({ icon = os.date("%a. %d %b.")
--   , label = os.date("%I:%M %p") })
-- end)
