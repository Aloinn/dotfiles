-- Define the Lua function to fold imports
function _G.fold_imports()
  local line = vim.fn.getline(vim.fn.line('.'))
  -- Fold lines that start with 'import'
  if line:match("^import") then
    return 1  -- Fold the line
  else
    return 0  -- Do not fold other lines
  end
end

return {
  "kevinhwang91/nvim-ufo",
  event = "BufReadPost",
  dependencies = {
    "kevinhwang91/promise-async",
  },
  opts = {
    openFoldsExceptKinds = { "imports", "functions" },
 },
}

