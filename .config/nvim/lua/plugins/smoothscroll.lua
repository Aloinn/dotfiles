return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",

  opts = {
    duration_multiplier = 1.0,
    easing = "quadratic",
  },

  keys = {
    -- { "[", function() require("neoscroll").ctrl_u({ duration = 50 }) end, desc = "Scroll Up" },
    -- { "]", function() require("neoscroll").ctrl_d({ duration = 50 }) end, desc = "Scroll Down" },
    -- { "{", function() require("neoscroll").ctrl_b({ duration = 50 }) end, desc = "Page Up" },
    -- { "}", function() require("neoscroll").ctrl_f({ duration = 50 }) end, desc = "Page Down" },
    { "zz", function() require("neoscroll").zz({ half_win_duration = 200 }) end, desc = "Center Cursor" },
    { "zt", function() require("neoscroll").zt({ half_win_duration = 200 }) end, desc = "Top Cursor" },
    { "zb", function() require("neoscroll").zb({ half_win_duration = 200 }) end, desc = "Bottom Cursor" },
    { "{", function() require("neoscroll").scroll(-45, { move_cursor=false; duration=100 }) end, desc = "Bottom Cursor" },
    { "[", function() require("neoscroll").scroll(-15, { move_cursor=false; duration=100 }) end, desc = "Bottom Cursor" },
    { "}", function() require("neoscroll").scroll(45, { move_cursor=false; duration=100 }) end, desc = "Bottom Cursor" },
    { "]", function() require("neoscroll").scroll(15, { move_cursor=false; duration=100 }) end, desc = "Bottom Cursor" },
  },
}
