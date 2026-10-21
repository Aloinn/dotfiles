local M = {}

-- Hosts allowed to load Amazon-internal plugins (git.amazon.com URLs).
local AMAZON_HOSTS = {
  ["6cb133a1d2fd"] = true, -- Mac
  ["dev-dsk-alainlam-2a-d7febfa4.us-west-2.amazon.com"] = true, -- cloud desktop
}

-- True if the full hostname or its short form (before the first dot) is allowed.
function M.is_amazon_host()
  local name = vim.fn.hostname()
  return AMAZON_HOSTS[name] == true or AMAZON_HOSTS[name:match "^[^.]+"] == true
end

return M
