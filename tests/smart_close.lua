-- nvim --headless --clean -u NONE -l tests/smart_close.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p')))
vim.opt.rtp:prepend(root)
local utilities = require('utilities')
local function panel()
  vim.cmd('only')
  local source = vim.api.nvim_get_current_buf()
  vim.cmd('belowright split')
  utilities.remember_smart_close()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide'
  vim.api.nvim_set_current_buf(buf)
  return buf, source
end
local function layout() return vim.deepcopy(vim.fn.winlayout()) end
local buf, source = panel()
local before = layout()
local calls = {}
assert(utilities.smart_close({ before = function(ctx)
  assert(ctx.buf == buf and ctx.win == vim.api.nvim_get_current_win()); calls[#calls + 1] = 'before'
end, after = function(ctx)
  assert(ctx.buf == buf and vim.api.nvim_get_current_buf() == source); calls[#calls + 1] = 'after'
end }))
assert(vim.deep_equal(calls, { 'before', 'after' }) and vim.deep_equal(layout(), before))
assert(not vim.api.nvim_buf_is_loaded(buf))

-- Cancellation has no side effects and skips after.
buf = panel(); before = layout()
assert(not utilities.smart_close({ before = function() return false end,
  after = function() error('after ran on cancellation') end }))
assert(vim.api.nvim_get_current_buf() == buf and vim.deep_equal(layout(), before))
assert(utilities.smart_close({ keep_buffer = true }))
assert(vim.api.nvim_buf_is_loaded(buf) and #vim.fn.win_findbuf(buf) == 0)

-- Plugin handlers select defaults by context; nil allows another handler to match.
buf = panel(); vim.bo[buf].filetype = 'example-panel'
local unregister = utilities.register_smart_close('example-plugin', function(ctx)
  if ctx.filetype == 'example-panel' then return { keep_buffer = true } end
end)
local unrelated = utilities.register_smart_close('other-plugin', function() return nil end)
assert(utilities.smart_close() and vim.api.nvim_buf_is_loaded(buf))
unrelated(); unregister()

-- A replacement registration survives an older unregister closure.
local old = utilities.register_smart_close('example-plugin', function() return false end)
local current = utilities.register_smart_close('example-plugin', function() return { keep_buffer = true } end)
old(); buf = panel()
assert(utilities.smart_close() and vim.api.nvim_buf_is_loaded(buf))
current()
local cancel = utilities.register_smart_close('cancel', function() return false end)
buf = panel(); assert(not utilities.smart_close() and vim.api.nvim_get_current_buf() == buf); cancel()
assert(utilities.smart_close())

-- Explicit options override registered defaults.
local keep = utilities.register_smart_close('keep', function() return { keep_buffer = true } end)
buf = panel(); assert(utilities.smart_close({ keep_buffer = false }))
assert(not vim.api.nvim_buf_is_loaded(buf)); keep()

-- Custom actions can delegate, close an owned window, or cancel.
buf = panel(); before = layout()
assert(not utilities.smart_close({ close = function() return false end }))
assert(vim.deep_equal(layout(), before) and vim.api.nvim_get_current_buf() == buf)
assert(utilities.smart_close({ close = function(ctx, default_close)
  assert(ctx.buf == buf); return default_close()
end }))
assert(vim.deep_equal(layout(), before))
buf = panel(); local win = vim.api.nvim_get_current_win()
assert(utilities.smart_close({ close = function(ctx) vim.api.nvim_win_close(ctx.win, false); return true end }))
assert(not vim.api.nvim_win_is_valid(win))

-- A plugin can choose a different return buffer.
buf = panel()
local replacement = vim.api.nvim_create_buf(true, false)
assert(utilities.smart_close({ replacement = function(ctx) assert(ctx.buf == buf); return replacement end }))
assert(vim.api.nvim_get_current_buf() == replacement)

-- Modified buffers are protected unless the caller explicitly authorizes discard.
buf = panel(); vim.bo[buf].buftype = ''; vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'draft' })
assert(not utilities.smart_close())
assert(vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified)
assert(utilities.smart_close({ force = true }))
assert(not vim.api.nvim_buf_is_loaded(buf))

-- All split windows showing a deleted buffer survive.
buf = panel(); vim.cmd('vsplit')
before = layout()
assert(utilities.smart_close())
assert(vim.deep_equal(layout(), before) and #vim.fn.win_findbuf(buf) == 0)

-- Closed source buffers fall back to a normal buffer without changing the layout.
buf, source = panel(); vim.api.nvim_buf_delete(source, { force = true })
before = layout(); assert(utilities.smart_close())
assert(vim.deep_equal(layout(), before) and vim.bo.buftype == '')
print('PASS: callbacks, cancellation, registration/replacement/unregister, overrides, custom actions, drafts and shared buffers')
