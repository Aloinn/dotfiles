local colors = require("colors")
local settings = require("settings")

-- local w_count = sbar.add("item", "w_count", {
--   position = "right",
--   display = "active",
--   icon = { drawing = false },
--   background = { color = colors.red },
--   popup = { align = "center" },
--   label = {
--     padding_left = 10,
--     padding_right= 8,
--     align="center",
--     font = {
--       family = settings.font.text,
--       style = settings.font.style_map["Bold"],
--       size = 14.0,
--     },
--   },
--   updates = true,
-- })

local front_app = sbar.add("item", "front_app", {
  position = "right",
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 14.0,
    },
  },
  updates = true,
})



front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
  -- w_count:set({label = {string="?"}})
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
