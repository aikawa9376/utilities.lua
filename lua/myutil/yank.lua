
--=============================================================================
-- FILE: yank.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.yank_remove_line()
  local tmp = vim.fn.getreg('"')
  local pos = vim.fn.getpos('.')
  local yank = tmp:gsub('^\_s\+', ''):gsub('\_s\_$', '')
  vim.fn.setreg('"', yank)
  vim.cmd('normal! ""p')
  vim.fn.setreg('"', tmp)
end

function M.yank_line(flag)
  local line_num
  if flag == 'j' then
    line_num = vim.fn.line('.')
  else
    line_num = vim.fn.line('.') - 1
  end
  vim.fn.append(line_num, '')
  vim.cmd('normal! ' .. flag .. 'p=`]^')
end

function M.yank_text_toggle()
  if vim.b.yank_toggle_flag ~= 0 then
    vim.cmd('normal! `[')
    vim.b.yank_toggle_flag = 0
  else
    vim.cmd('normal! `]')
    vim.b.yank_toggle_flag = 1
  end
end

function M.yank_toggle_flag()
  vim.b.yank_toggle_flag = 1
end

return M
