
--=============================================================================
-- FILE: toggle.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.toggle_syntax()
  if vim.g.syntax_on then
    vim.cmd('syntax off')
    vim.cmd('redraw')
    print('syntax off')
  else
    vim.cmd('syntax on')
    vim.cmd('redraw')
    print('syntax on')
  end
end

function M.toggle_relativenumber()
  vim.opt_local.relativenumber = not vim.opt_local.relativenumber:get()
end

function M.hl_text_toggle()
  if vim.v.hlsearch ~= 0 then
    vim.cmd('noh')
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Plug>(my-hltoggle)', true, false, true), 'n', false)
  end
end

return M
