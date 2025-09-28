
--=============================================================================
-- FILE: fs.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.auto_mkdir(dir, force)
  if not vim.fn.isdirectory(dir) and (force or vim.fn.input(string.format('"%s" does not exist. Create? [y/N]', dir)):match('^[yY]')) then
    vim.fn.mkdir(dir, 'p')
  end
end

function M.vimrc_local(loc)
  local files = vim.fn.findfile('.vimrc.local', vim.fn.escape(loc, ' ') .. ';', -1)
  for _, file in ipairs(vim.fn.reverse(files)) do
    if vim.fn.filereadable(file) == 1 then
      vim.cmd('source ' .. file)
    end
  end
end

return M
