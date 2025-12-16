
  -- [yazi] file browser
  -- https://github.com/mikavilpas/yazi.nvim
  -- Make sure you have yazi installed on your system!
 return {
    "mikavilpas/yazi.nvim",
    event = "User BaseDefered",
    cmd = { "Yazi", "Yazi cwd", "Yazi toggle" },
    opts = {
        -- open_for_directories = true,
        floating_window_scaling_factor = (is_android and 1.0) or 0.71
    },
  }
