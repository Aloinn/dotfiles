-- Self-managed sessions: per-project-root JSON store of open buffers
-- (project files only) and project-scoped marks (a-z, accessible from any
-- buffer while cwd is inside the project).
--
-- Replaces persisted.nvim (mksession) and marks.nvim.
--
-- Store: stdpath("data")/self-sessions/<escaped-project-root>.json
-- {
--   buffers = { { path, row, col }, ... },   -- listed project buffers
--   active  = "path",                        -- buffer to focus on load
--   marks   = { a = { path, line, col }, ... },
--   breakpoints = { { path, line, condition?, log_message?, hit_condition? }, ... },
-- }
--
-- Project root resolution (same as the old persisted.nvim setup):
-- realpath(cwd) [fixes /home -> /local/home symlink], then walk up to the
-- Brazil workspace root (.bemol/packageInfo) or git root.

local M = {}

local ns = vim.api.nvim_create_namespace("self_session_marks")

local root = nil -- resolved project root (realpath)
local store_file = nil
local state = { buffers = {}, active = nil, marks = {}, breakpoints = {} }
local mark_extmarks = {} -- key -> { buf = bufnr, id = extmark_id }
local pending_cursor = {} -- path -> { row, col }, applied on BufReadPost
local save_timer = nil

-- ── Project root ────────────────────────────────────────────────────────

local function project_root(dir)
  -- Brazil ws markers first: each package is its own git repo, so a plain
  -- .git search from inside a package would stop at the package.
  local ws = vim.fs.find({ ".bemol", "packageInfo" }, { path = dir, upward = true })[1]
  if ws then
    return vim.fs.dirname(ws)
  end
  local git = vim.fs.find({ ".git" }, { path = dir, upward = true })[1]
  if git then
    return vim.fs.dirname(git)
  end
  return dir
end

local function resolve_root()
  local real_cwd = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
  root = project_root(real_cwd)
  if root ~= vim.fn.getcwd() then
    vim.cmd.cd(root)
  end
  store_file = vim.fn.stdpath("data")
    .. "/self-sessions/"
    .. root:gsub("[/\\:]", "%%")
    .. ".json"
end

-- ── Helpers ─────────────────────────────────────────────────────────────

local function realpath(p)
  return vim.uv.fs_realpath(p) or p
end

local function is_project_path(path)
  return path ~= "" and vim.startswith(realpath(path), root .. "/")
end

local function is_project_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  return is_project_path(vim.api.nvim_buf_get_name(buf))
end

-- Loaded buffer for a stored (real)path, or nil
local function find_buf(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and realpath(name) == path then
        return buf
      end
    end
  end
  return nil
end

local function refresh_sidebar()
  vim.schedule(function()
    local ok, sbn = pcall(require, "sidebar-nvim")
    if ok then
      sbn.update()
    end
  end)
end

-- ── Treesitter / filetype kick ──────────────────────────────────────────
-- nvim-treesitter is lazy-loaded on BufReadPost and attaches highlighting
-- via a FileType hook. During session restore, FileType fires BEFORE the
-- plugin is loaded (first :edit) or is skipped entirely (bufadd'd
-- background buffers loaded later), leaving restored files without
-- highlighting. Re-fire FileType for the buffer once treesitter is up.
local function ensure_highlight(buf)
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end
    if vim.treesitter.highlighter.active[buf] then
      return -- already highlighted
    end
    if not package.loaded["nvim-treesitter"] then
      pcall(function()
        require("lazy").load({ plugins = { "nvim-treesitter" } })
      end)
    end
    vim.api.nvim_buf_call(buf, function()
      local ft = vim.bo[buf].filetype
      if ft == "" then
        vim.cmd("filetype detect")
        ft = vim.bo[buf].filetype
      else
        vim.cmd("doautocmd FileType " .. ft)
      end
    end)
    -- Direct fallback: attach the core highlighter ourselves if the
    -- nvim-treesitter FileType hook didn't do it
    if not vim.treesitter.highlighter.active[buf] then
      pcall(vim.treesitter.start, buf)
    end
  end)
end

-- ── Mark signs ──────────────────────────────────────────────────────────

local function remove_sign(key)
  local em = mark_extmarks[key]
  if em and vim.api.nvim_buf_is_valid(em.buf) then
    pcall(vim.api.nvim_buf_del_extmark, em.buf, ns, em.id)
  end
  mark_extmarks[key] = nil
end

local function place_sign(key)
  local mk = state.marks[key]
  if not mk then
    return
  end
  remove_sign(key)
  local buf = find_buf(mk.path)
  if not buf or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local line = math.min(mk.line, vim.api.nvim_buf_line_count(buf)) - 1
  local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, line, 0, {
    sign_text = key,
    sign_hl_group = "DiagnosticSignHint",
  })
  if ok then
    mark_extmarks[key] = { buf = buf, id = id }
  end
end

-- ── Collect & persist ───────────────────────────────────────────────────

-- Pull live extmark positions back into mark state (extmarks track edits)
local function sync_marks_from_extmarks()
  for key, em in pairs(mark_extmarks) do
    local mk = state.marks[key]
    if mk and vim.api.nvim_buf_is_valid(em.buf) then
      local pos = vim.api.nvim_buf_get_extmark_by_id(em.buf, ns, em.id, {})
      if pos and #pos == 2 then
        mk.line = pos[1] + 1
        mk.col = pos[2]
      end
    end
  end
end

-- DAP breakpoints -> state.breakpoints. Only when nvim-dap is actually
-- loaded (it lazy-loads on ft=java); otherwise keep whatever was loaded
-- from the store so a non-java session doesn't wipe saved breakpoints.
local function collect_breakpoints()
  if not package.loaded["dap"] then
    return
  end
  local ok, dap_bps = pcall(function()
    return require("dap.breakpoints").get()
  end)
  if not ok then
    return
  end
  local bps = {}
  for bufnr, bp_list in pairs(dap_bps) do
    if is_project_buf(bufnr) then
      local path = realpath(vim.api.nvim_buf_get_name(bufnr))
      for _, bp in ipairs(bp_list) do
        table.insert(bps, {
          path = path,
          line = bp.line,
          -- get() returns camelCase; set() takes snake_case. Store snake.
          condition = bp.condition,
          log_message = bp.logMessage,
          hit_condition = bp.hitCondition,
        })
      end
    end
  end
  state.breakpoints = bps
end

local function collect()
  -- Cursor positions: prefer live window cursors
  local win_pos = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    win_pos[buf] = vim.api.nvim_win_get_cursor(win)
  end

  -- Previous stored positions as fallback for background buffers
  local prev = {}
  for _, b in ipairs(state.buffers) do
    prev[b.path] = { b.row, b.col }
  end

  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_project_buf(buf) then
      local path = realpath(vim.api.nvim_buf_get_name(buf))
      local pos = win_pos[buf]
      if not pos and vim.api.nvim_buf_is_loaded(buf) then
        local m = vim.api.nvim_buf_get_mark(buf, '"')
        if m[1] > 0 then
          pos = m
        end
      end
      pos = pos or prev[path] or { 1, 0 }
      table.insert(buffers, { path = path, row = pos[1], col = pos[2] })
    end
  end
  state.buffers = buffers

  local cur = vim.api.nvim_get_current_buf()
  if is_project_buf(cur) then
    state.active = realpath(vim.api.nvim_buf_get_name(cur))
  end

  sync_marks_from_extmarks()
  collect_breakpoints()
end

function M.save()
  if not root then
    return
  end
  collect()
  -- Don't clobber a previous session with an empty one (e.g. nvim opened
  -- and closed without touching any project file)
  if #state.buffers == 0 and vim.tbl_isempty(state.marks) and #(state.breakpoints or {}) == 0 then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(store_file, ":h"), "p")
  local tmp = store_file .. "." .. vim.uv.os_getpid() .. ".tmp"
  local fd = io.open(tmp, "w")
  if not fd then
    vim.notify("self_session: cannot write " .. tmp, vim.log.levels.ERROR)
    return
  end
  fd:write(vim.json.encode(state))
  fd:close()
  os.rename(tmp, store_file) -- atomic: last writer wins
end

local function schedule_save()
  if save_timer then
    save_timer:stop()
    save_timer:close()
  end
  save_timer = vim.uv.new_timer()
  save_timer:start(2000, 0, vim.schedule_wrap(function()
    save_timer:close()
    save_timer = nil
    M.save()
  end))
end

-- ── Breakpoint restore ──────────────────────────────────────────────────

-- Apply stored breakpoints via nvim-dap. Buffer must be loaded for the
-- extmark + sign to land.
local function restore_breakpoints()
  if #(state.breakpoints or {}) == 0 then
    return
  end
  local ok, dap_bps = pcall(require, "dap.breakpoints")
  if not ok then
    return
  end
  for _, bp in ipairs(state.breakpoints) do
    if vim.fn.filereadable(bp.path) == 1 then
      local buf = vim.fn.bufadd(bp.path)
      if not vim.api.nvim_buf_is_loaded(buf) then
        pcall(vim.fn.bufload, buf)
      end
      local line = math.min(bp.line, vim.api.nvim_buf_line_count(buf))
      pcall(dap_bps.set, {
        condition = bp.condition,
        log_message = bp.log_message,
        hit_condition = bp.hit_condition,
      }, buf, line)
    end
  end
end

-- nvim-dap lazy-loads on ft=java; requiring it here at session load would
-- force the whole dap/dapui/hydra chain to load at startup. Instead restore
-- immediately if dap is already loaded, else once lazy.nvim loads it.
local restored = false
local function restore_breakpoints_when_ready()
  if restored then
    return
  end
  if package.loaded["dap"] then
    restored = true
    restore_breakpoints()
    return
  end
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyLoad",
    callback = function(ev)
      if ev.data == "nvim-dap" and not restored then
        restored = true
        -- schedule: let dap finish its own setup first
        vim.schedule(restore_breakpoints)
      end
    end,
  })
end

-- ── Load ────────────────────────────────────────────────────────────────

function M.load()
  if not root then
    resolve_root()
  end
  local fd = io.open(store_file, "r")
  if not fd then
    return false
  end
  local raw = fd:read("*a")
  fd:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    vim.notify("self_session: corrupt store " .. store_file, vim.log.levels.WARN)
    return false
  end
  state.buffers = decoded.buffers or {}
  state.active = decoded.active
  state.marks = decoded.marks or {}
  state.breakpoints = decoded.breakpoints or {}
  -- vim.json decodes {} as empty list; normalize
  if vim.islist(state.marks) then
    state.marks = {}
  end

  pending_cursor = {}
  local active_exists = false
  for _, b in ipairs(state.buffers) do
    if vim.fn.filereadable(b.path) == 1 then
      local buf = vim.fn.bufadd(b.path)
      vim.bo[buf].buflisted = true
      pending_cursor[b.path] = { b.row, b.col }
      if b.path == state.active then
        active_exists = true
      end
    end
  end

  local to_open = active_exists and state.active
    or (state.buffers[1] and state.buffers[1].path)
  if to_open and vim.fn.filereadable(to_open) == 1 then
    local initial = vim.api.nvim_get_current_buf()
    vim.cmd.edit(vim.fn.fnameescape(to_open))
    ensure_highlight(vim.api.nvim_get_current_buf())
    local pos = pending_cursor[to_open]
    if pos then
      pcall(vim.api.nvim_win_set_cursor, 0, { pos[1], pos[2] })
      pending_cursor[to_open] = nil
    end
    -- Wipe the startup no-name buffer if it's still around and untouched
    if
      initial ~= vim.api.nvim_get_current_buf()
      and vim.api.nvim_buf_is_valid(initial)
      and vim.api.nvim_buf_get_name(initial) == ""
      and not vim.bo[initial].modified
    then
      pcall(vim.api.nvim_buf_delete, initial, {})
    end
  end

  -- Force-load every restored buffer so filetype detection and treesitter
  -- highlighting attach NOW, not lazily on first visit
  for _, b in ipairs(state.buffers) do
    local buf = find_buf(b.path)
    if buf then
      if not vim.api.nvim_buf_is_loaded(buf) then
        pcall(vim.fn.bufload, buf)
      end
      ensure_highlight(buf)
    end
  end

  -- After force-load so signs land in loaded buffers
  for key in pairs(state.marks) do
    place_sign(key)
  end

  restore_breakpoints_when_ready()

  refresh_sidebar()
  return true
end

-- ── Marks API ───────────────────────────────────────────────────────────

function M.set_mark(key)
  local buf = vim.api.nvim_get_current_buf()
  if not is_project_buf(buf) then
    vim.notify("self_session: not a project file", vim.log.levels.WARN)
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local prev = state.marks[key]
  state.marks[key] = {
    path = realpath(vim.api.nvim_buf_get_name(buf)),
    line = pos[1],
    col = pos[2],
    name = prev and prev.name or nil,
  }
  place_sign(key)
  M.save()
  refresh_sidebar()
end

function M.jump_mark(key)
  local mk = state.marks[key]
  if not mk then
    vim.notify("self_session: mark '" .. key .. "' not set", vim.log.levels.WARN)
    return
  end
  sync_marks_from_extmarks()
  local buf = find_buf(mk.path)
  if buf and vim.api.nvim_buf_is_loaded(buf) then
    vim.api.nvim_set_current_buf(buf)
  else
    vim.cmd.edit(vim.fn.fnameescape(mk.path))
  end
  local line = math.min(mk.line, vim.api.nvim_buf_line_count(0))
  pcall(vim.api.nvim_win_set_cursor, 0, { line, mk.col or 0 })
end

function M.delete_mark(key)
  if not state.marks[key] then
    return
  end
  remove_sign(key)
  state.marks[key] = nil
  M.save()
  refresh_sidebar()
end

-- Name (or rename) a mark. Sets the mark at the cursor first if unset.
-- Empty input clears the name; <Esc> cancels without changes.
function M.name_mark(key)
  if not state.marks[key] then
    M.set_mark(key)
    if not state.marks[key] then
      return -- set_mark refused (not a project file)
    end
  end
  local mk = state.marks[key]
  vim.ui.input(
    { prompt = "Name for mark [" .. key .. "]: ", default = mk.name or "" },
    function(input)
      if input == nil then
        return -- cancelled
      end
      mk.name = input ~= "" and input or nil
      M.save()
      refresh_sidebar()
    end
  )
end

-- Sorted list for the sidebar section
function M.marks_list()
  sync_marks_from_extmarks()
  local items = {}
  for key, mk in pairs(state.marks) do
    table.insert(items, {
      key = key,
      path = mk.path,
      line = mk.line,
      col = mk.col or 0,
      name = mk.name,
    })
  end
  table.sort(items, function(a, b)
    return a.key < b.key
  end)
  return items
end

-- ── Setup ───────────────────────────────────────────────────────────────

function M.setup()
  resolve_root()

  local group = vim.api.nvim_create_augroup("self_session", { clear = true })

  -- Autoload when nvim was started without file args
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    nested = true,
    once = true,
    callback = function()
      if vim.fn.argc() == 0 then
        M.load()
      end
    end,
  })

  -- Restore cursor + place mark signs when a stored file gets loaded
  -- BufWinEnter too: force-loaded (bufload) buffers may never fire
  -- BufReadPost, so apply the pending cursor on first visit instead
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
    group = group,
    callback = function(args)
      local path = realpath(vim.api.nvim_buf_get_name(args.buf))
      local pos = pending_cursor[path]
      -- Only when the buffer is shown in a real window: nvim_buf_call
      -- (ensure_highlight) runs these events in a temp "autocmd" window
      -- whose cursor position is thrown away
      if pos and vim.api.nvim_get_current_buf() == args.buf and vim.fn.win_gettype() == "" then
        pending_cursor[path] = nil
        local line = math.min(pos[1], vim.api.nvim_buf_line_count(args.buf))
        pcall(vim.api.nvim_win_set_cursor, 0, { line, pos[2] })
      end
      for key, mk in pairs(state.marks) do
        if mk.path == path then
          place_sign(key)
        end
      end
      if is_project_path(path) then
        ensure_highlight(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWinEnter", "FocusLost" }, {
    group = group,
    callback = schedule_save,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.save()
    end,
  })

  -- Keymaps: lowercase a-z = project marks; everything else falls through
  -- to native behavior (uppercase/numbered marks, '<, '', etc.)
  vim.keymap.set("n", "m", function()
    local ch = vim.fn.getcharstr()
    if ch:match("^[a-z]$") then
      M.set_mark(ch)
    else
      vim.api.nvim_feedkeys("m" .. ch, "n", false)
    end
  end, { desc = "set mark (a-z: project mark)" })

  for _, lhs in ipairs({ "'", "`" }) do
    vim.keymap.set("n", lhs, function()
      local ch = vim.fn.getcharstr()
      if ch:match("^[a-z]$") then
        M.jump_mark(ch)
      else
        vim.api.nvim_feedkeys(lhs .. ch, "n", false)
      end
    end, { desc = "jump to mark (a-z: project mark)" })
  end

  vim.keymap.set("n", "dm", function()
    local ch = vim.fn.getcharstr()
    if ch:match("^[a-z]$") then
      M.delete_mark(ch)
    end
  end, { desc = "delete project mark" })

  -- M{a-z}: name a project mark (sets it at cursor first if unset).
  -- Any other char falls through to native M (middle of screen) + char.
  vim.keymap.set("n", "M", function()
    local ch = vim.fn.getcharstr()
    if ch:match("^[a-z]$") then
      M.name_mark(ch)
    else
      vim.api.nvim_feedkeys("M" .. ch, "n", false)
    end
  end, { desc = "name project mark (M{a-z})" })

  vim.api.nvim_create_user_command("SelfSessionSave", M.save, {})
  vim.api.nvim_create_user_command("SelfSessionLoad", M.load, {})
end

return M
