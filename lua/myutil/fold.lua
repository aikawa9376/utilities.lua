

--=============================================================================
-- FILE: fold.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.custom_fold_text()
  local foldstart = vim.v.foldstart
  local foldend = vim.v.foldend
  local foldlevel = vim.v.foldlevel

  local fs = foldstart
  while vim.fn.getline(fs):match('^\s*$') do
    fs = vim.fn.nextnonblank(fs + 1)
  end

  local line
  if fs > foldend then
    line = vim.fn.getline(foldstart)
  else
    line = vim.fn.substitute(vim.fn.getline(fs), '\t', string.rep(' ', vim.o.tabstop), 'g')
  end

  local foldsymbol = '+'
  local repeatsymbol = ''
  local prefix = foldsymbol .. ' '

  local w = vim.fn.winwidth(0) - vim.o.foldcolumn - (vim.o.number and 8 or 0)
  local foldSize = 1 + foldend - foldstart
  local foldSizeStr = ' ' .. foldSize .. ' lines '
  local foldLevelStr = string.rep('+--', foldlevel)
  local lineCount = vim.fn.line('$')
  local foldPercentage = string.format('[%.1f', (foldSize * 1.0) / lineCount * 100) .. '%%] '
  local expansionString = string.rep(repeatsymbol, w - vim.fn.strwidth(prefix .. foldSizeStr .. line .. foldLevelStr .. foldPercentage))

  return prefix .. line .. expansionString .. foldSizeStr .. foldPercentage .. foldLevelStr
end

return M
