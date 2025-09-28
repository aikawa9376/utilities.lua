
--=============================================================================
-- FILE: commands.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.setup()
  vim.api.nvim_create_user_command(
    'Capture',
    function(opts)
      require('myutil.capture').cmd_capture(opts, opts.bang)
    end,
    { nargs = '+', bang = true, complete = 'command' }
  )

  vim.api.nvim_create_user_command(
    'TERM',
    function(opts)
      vim.cmd('split | resize 20 | term ' .. table.concat(opts.fargs, ' '))
    end,
    { nargs = '*' }
  )
end

return M
