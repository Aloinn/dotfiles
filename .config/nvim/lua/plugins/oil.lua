return {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
        skip_confirm_for_simple_edits = false,
        view_options = {
            -- Show files and directories that start with "."
            show_hidden = true,
            -- This function defines what is considered a "hidden" file
            is_hidden_file = function(name, _)
                local m = name:match("^%.")
                return m ~= nil
            end,
            -- This function defines what will never be shown, even when `show_hidden` is set
            is_always_hidden = function(_, _)
                return false
            end,
        },
    },
}
