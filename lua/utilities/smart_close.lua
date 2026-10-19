local M = {}
local returns, handlers, order = {}, {}, {}
local option_names = { 'number', 'relativenumber', 'wrap', 'list', 'signcolumn', 'statuscolumn',
  'foldmethod', 'foldenable', 'foldcolumn', 'foldexpr', 'foldtext', 'conceallevel', 'concealcursor' }

vim.api.nvim_create_autocmd('WinClosed', {
  group = vim.api.nvim_create_augroup('UtilitiesSmartClose', { clear = true }),
  callback = function(ev) returns[tonumber(ev.match)] = nil end,
})

---Remember the buffer, view and local display options to restore in this window.
---@param opts? { source_win?: integer, created?: boolean, preserve?: boolean }
function M.remember(opts)
  opts = opts or {}
  local win = vim.api.nvim_get_current_win()
  if opts.preserve and returns[win] then return end
  local source = opts.source_win or win
  local created = opts.created
  if created == nil then created = source ~= win end
  local options = {}
  for _, name in ipairs(option_names) do
    options[name] = vim.api.nvim_get_option_value(name, { win = source, scope = 'local' })
  end
  returns[win] = { buf = vim.api.nvim_win_get_buf(source), options = options,
    view = vim.api.nvim_win_call(source, vim.fn.winsaveview), source_win = source, created = created }
end

---Register a named resolver. Newest matching resolver wins; nil means no match.
---Return an options table, or false to cancel. Registering the same name replaces it.
---@param name string
---@param callback fun(ctx: table): table|false|nil
---@return function unregister
function M.register(name, callback)
  assert(type(name) == 'string' and type(callback) == 'function')
  if not handlers[name] then order[#order + 1] = name end
  handlers[name] = callback
  return function()
    if handlers[name] ~= callback then return end
    handlers[name] = nil
    for index, registered in ipairs(order) do
      if registered == name then table.remove(order, index); break end
    end
  end
end

local function available(buf, closing)
  return buf and buf > 0 and buf ~= closing and vim.api.nvim_buf_is_loaded(buf)
end

local function default_close(ctx, opts)
  local saved = returns[ctx.win]
  local function delete_hidden()
    if not opts.keep_buffer and vim.api.nvim_buf_is_valid(ctx.buf) and #vim.fn.win_findbuf(ctx.buf) == 0 then
      vim.api.nvim_buf_delete(ctx.buf, { force = opts.force or false })
    end
  end
  local config = vim.api.nvim_win_get_config(ctx.win)
  if config.relative ~= '' or config.external then
    vim.api.nvim_win_close(ctx.win, opts.force or false)
    delete_hidden()
    return true
  end
  local count = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(ctx.tab)) do
    local candidate = vim.api.nvim_win_get_config(win)
    if candidate.relative == '' and not candidate.external then count = count + 1 end
  end
  if (not saved or saved.created) and (count > 1 or #vim.api.nvim_list_tabpages() > 1) then
    vim.api.nvim_win_close(ctx.win, opts.force or false)
    delete_hidden()
    if saved and vim.api.nvim_win_is_valid(saved.source_win) then
      vim.api.nvim_set_current_win(saved.source_win)
    end
    return true
  end

  for _, win in ipairs({ ctx.win }) do
    local saved = returns[win]
    local replacement = opts.replacement and opts.replacement(vim.tbl_extend('force', ctx, { win = win }))
    if not available(replacement, ctx.buf) then replacement = saved and saved.buf end
    if not available(replacement, ctx.buf) then
      replacement = vim.api.nvim_win_call(win, function() return vim.fn.bufnr('#') end)
    end
    if not available(replacement, ctx.buf) then
      replacement = nil
      local buffers = vim.fn.getbufinfo({ buflisted = 1 })
      table.sort(buffers, function(a, b) return a.lastused > b.lastused end)
      for _, candidate in ipairs(buffers) do
        if available(candidate.bufnr, ctx.buf) and vim.bo[candidate.bufnr].buftype == '' then
          replacement = candidate.bufnr; break
        end
      end
    end
    if not available(replacement, ctx.buf) then replacement = vim.api.nvim_create_buf(true, false) end
    returns[win] = nil
    vim.api.nvim_win_set_buf(win, replacement)
    for name, value in pairs(saved and saved.options or {}) do
      vim.api.nvim_set_option_value(name, value, { win = win, scope = 'local' })
    end
    if saved and replacement == saved.buf then
      vim.api.nvim_win_call(win, function() vim.fn.winrestview(saved.view) end)
    end
  end
  delete_hidden()
  return true
end

---Close windows by default; a remembered reused window restores its prior buffer.
---before(ctx) may return false to cancel; after(ctx) runs only after success.
---close(ctx, default_close) can replace or delegate the close action.
---replacement(ctx) selects a buffer for each affected window.
---@param opts? { keep_buffer?: boolean, force?: boolean, before?: function, after?: function, close?: function, replacement?: function }
---@return boolean closed
function M.close(opts)
  local ctx = { buf = vim.api.nvim_get_current_buf(), win = vim.api.nvim_get_current_win(),
    tab = vim.api.nvim_get_current_tabpage(), filetype = vim.bo.filetype }
  local resolved = {}
  for index = #order, 1, -1 do
    local value = handlers[order[index]](ctx)
    if value == false then return false end
    if value ~= nil then resolved = value; break end
  end
  opts = vim.tbl_extend('force', resolved, opts or {})
  if opts.before and opts.before(ctx) == false then return false end
  if not vim.api.nvim_win_is_valid(ctx.win) or not vim.api.nvim_buf_is_valid(ctx.buf)
    or vim.api.nvim_win_get_buf(ctx.win) ~= ctx.buf then return false end
  vim.api.nvim_set_current_win(ctx.win)
  if vim.bo[ctx.buf].modified and not opts.force then
    vim.notify('No write since last change', vim.log.levels.WARN)
    return false
  end
  local function close_default() return default_close(ctx, opts) end
  local closed
  if opts.close then closed = opts.close(ctx, close_default) == true
  else closed = close_default() end
  if closed and opts.after then opts.after(ctx) end
  return closed
end

return M
