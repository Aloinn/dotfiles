-- Custom sidebar.nvim section: bookmarks.nvim integration
local cached_bookmarks = {}

local function refresh_bookmarks()
  local ok, service = pcall(require, "bookmarks.domain.service")
  if not ok then return end
  local ok2, result = pcall(service.get_all_bookmarks_of_active_list)
  if ok2 and result then
    cached_bookmarks = result
  end
end

local section = {
  title = "Bookmarks",
  icon = "󰃃",
  setup = function() 
    refresh_bookmarks()
  end,
  update = function()
    refresh_bookmarks()
  end,
  draw = function()
    local lines, hl = {}, {}
    for _, bm in ipairs(cached_bookmarks) do
      local name = bm.name ~= "" and bm.name or vim.fn.fnamemodify(bm.location.path, ":t")
      local line_nr = bm.location and bm.location.line or 0
      table.insert(lines, "  " .. name .. ":" .. line_nr)
    end
    if #lines == 0 then
      return { lines = { "  (no bookmarks)" }, hl = {} }
    end
    return { lines = lines, hl = hl }
  end,
  bindings = {
    ["<CR>"] = function(line)
      local bm = cached_bookmarks[line + 1]
      if bm then
        vim.cmd("wincmd p")
        require("bookmarks.domain.service").goto_bookmark(bm.id)
      end
    end,
    ["e"] = function(line)
      local bm = cached_bookmarks[line + 1]
      if bm then
        vim.cmd("wincmd p")
        require("bookmarks.domain.service").goto_bookmark(bm.id)
      end
    end,
    ["d"] = function(line)
      local bm = cached_bookmarks[line + 1]
      if bm then
        require("bookmarks.domain.service").remove_bookmark(bm.id)
        refresh_bookmarks()

      end
    end,
  },
}

return section
