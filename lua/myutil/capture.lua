
--=============================================================================
-- FILE: capture.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

local function capture(cmd)
  return vim.fn.execute(cmd)
end

function M.cmd_capture(args, banged)
  vim.cmd('new')
  vim.api.nvim_put({capture(table.concat(args.fargs, ' '))}, 'c', true, true)
  vim.cmd('1,2delete _')
end

return M
