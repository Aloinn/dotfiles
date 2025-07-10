local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local sorter = require("telescope.sorters")

local yabai_window_picker = function(opts)
  opts = opts or {}
  local output = vim.fn.system("yabai -m query --windows")

  -- Decode JSON into Lua table
  local windows = vim.fn.json_decode(output)
  local entries = {}
  for _, win in ipairs(windows) do
    table.insert(entries, {
      app = win.app,
      title = win.title,
      screen = win.display,
      visible = win["is-visible"],
      ordinal = (win["is-visible"] and "/V" or "/H") .. " /" .. win.display .. " " .. win.app .. " " .. win.title,
      id = win.id
    })
  end
 
  local displayer = entry_display.create({
    separator = " ",
    items = {
      {},
      {},
      {},
      {},
    },
  })

  local pcolors = {
    "TelescopeResultsClass",
    "TelescopeResultsConstant",
    "TelescopeResultsOperator",
    "TelescopeResultsVariable",
    "TelescopeResultsClass",
    "TelescopeResultsComment"
  }

  pickers.new(opts, {
    prompt_title = "Windows",
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function()
            return displayer {
              { "[" .. ((entry.visible) and "V" or "H") .. "]",  pcolors[(entry.visible) and 2 or 6] }, 
              { "[" .. entry.screen .. "]", pcolors[entry.screen] },   
              { entry.app, "TelescopeResultsIdentifier" },  -- Line 1: styled app
              { " - " ..entry.title, "TelescopeResultsComment" },   
            }
          end,
          ordinal = entry.ordinal,
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    sorting_strategy = "ascending",
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry().value
        vim.fn.system({ "yabai", "-m", "window", "--focus", tostring(selection.id) })
      end)
      return true
    end
  }):find()
end
local M = {}
local utils = require("base.utils")
local maps = require("base.utils").get_mappings_template()

-- SEARCH
-- maps.n["<D-z>"] = {colors, desc = "Search word under cursor" }
vim.api.nvim_create_user_command("YabaiWindows", function()
  yabai_window_picker()
end, {})

utils.set_mappings(maps)
return M
