-- local settings = require("settings")
-- local colors = require("colors")
-- -- #!/bin/bash
-- --
-- -- SLACK_INFO=$(lsappinfo info -only StatusLabel `lsappinfo find LSDisplayName=Slack`)
-- -- COUNT=${SLACK_INFO:25:1}
-- --
-- -- if [ $COUNT = "\"" ]; then
-- --   DRAWING=off
-- -- else
-- --   DRAWING=on
-- -- fi
-- --
-- -- sketchybar --set slack drawing=$DRAWING label="${COUNT}"
--
-- local slack = sbar.add("item", {
--   icon = {
--     font = { size = 18.0 },
--     string = icons.apple,
--     padding_right = 12,
--     padding_left = 12,
--   },
--   label = { drawing = false },
--   background = {
--     color = colors.red,
--     border_width = 0
--   },
--   padding_left = 1,
--   padding_right = 1,
--   -- click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
-- })
--

-- sbar.add("item", "slack")
--
--

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 1 })

local slack = sbar.add("item", {
  -- icon = {
  --   width = 20,
  --   label ="󰍢",
  --   color = colors.white,
  --   font = {
  --     style = settings.font.style_map["Regular"],
  --     size = 19.0,
  --   }
  -- },
  label = {
    color = colors.white,
    font = { family = settings.font.numbers, style="Bold", size=18.0 },
    padding_left = 8,
    align = "right",
  },
  padding_left = 1,
  padding_right = 1,
  padding_top = 10,
  width = 40,
  update_freq = 5,
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { slack.name }, {
  background = {
    color = colors.transparent,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 7 })
slack:subscribe({ "forced", "routine", "system_woke" }, function(env)
  sbar.exec("lsappinfo info -only StatusLabel `lsappinfo find LSDisplayName=Slack` | cut -c26", function(value)
    msg = value:match("%d") 
    slack:set({
      background = {
        color = msg and colors.red or colors.bar.bg 
      },
      label = (msg and value or "_")
    })
  end)
end)
-- slack:subscribe({"forced", "routine", "system_woke"}, function(env)
--   slack.set({
--       label = "test" 
--       })
--   -- sbar.exec("ls", function(info)
--   --   slack.set({
--   --     label = { string = "test" }
--   --     })
--   -- end)
-- end)
