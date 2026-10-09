-- DAP / JVM connection status, shared by the statusline and TEST-mode hint.
local M = {}

-- Returns (text, state) where state is "none" | "running" | "paused".
-- Never loads nvim-dap itself (it's lazy on ft=java).
function M.get()
    local dap = package.loaded["dap"]
    local session = dap and dap.session()
    if not session then
        return "no JVM", "none"
    end
    local cfg = session.config or {}
    local name = cfg.name or "session"
    if cfg.request == "attach" and cfg.port then
        -- "Attach: GTAS IAD (:5051)" -> "GTAS IAD :5051"
        name = name:gsub("^Attach:%s*", ""):gsub("%s*%(:%d+%)", "") .. " :" .. cfg.port
    end
    if #name > 40 then
        name = name:sub(1, 37) .. "..."
    end
    if session.stopped_thread_id then
        return name, "paused"
    end
    return name, "running"
end

-- Statusline segment (empty when no session, so it stays out of the way).
function M.statusline()
    local text, state = M.get()
    if state == "none" then
        return ""
    elseif state == "paused" then
        return "%#DiagnosticWarn# 󰏤 JVM " .. text .. " "
    end
    return "%#DiagnosticOk# 󰐊 JVM " .. text .. " "
end

-- Plain-text version for the hydra hint.
function M.hint()
    local text, state = M.get()
    if state == "none" then
        return "○ not connected"
    elseif state == "paused" then
        return "⏸ PAUSED  " .. text
    end
    return "● connected  " .. text
end

return M
