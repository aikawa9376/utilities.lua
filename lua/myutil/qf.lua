
--=============================================================================
-- FILE: qf.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

local function del_entry(mode)
  local qf = vim.fn.getqflist()
  local history = vim.w.qf_history or {}
  table.insert(history, vim.deepcopy(qf))
  vim.w.qf_history = history

  local firstline, lastline
  if mode == 'v' then
    firstline = vim.fn.line("'<")
    lastline = vim.fn.line("'>")
  else
    firstline = vim.fn.line('.')
    lastline = vim.fn.line('.')
  end

  local new_qf = {}
  for i, item in ipairs(qf) do
    if i < firstline or i > lastline then
      table.insert(new_qf, item)
    end
  end

  vim.fn.setqflist(new_qf, 'r')
  vim.api.nvim_win_set_cursor(0, {firstline, 0})
end

local function undo_entry()
  local history = vim.w.qf_history or {}
  if #history > 0 then
    vim.fn.setqflist(table.remove(history), 'r')
  end
end

function M.qf_enhanced()
  vim.keymap.set('n', 'p', '<CR>zz<C-w>p', { buffer = true })
  vim.keymap.set('n', 'dd', function() del_entry('n') end, { buffer = true, silent = true })
  vim.keymap.set('n', 'x', function() del_entry('n') end, { buffer = true, silent = true })
  vim.keymap.set('v', 'd', function() del_entry('v') end, { buffer = true, silent = true })
  vim.keymap.set('v', 'x', function() del_entry('v') end, { buffer = true, silent = true })
  vim.keymap.set('n', 'u', undo_entry, { buffer = true, silent = true })
end

return M
