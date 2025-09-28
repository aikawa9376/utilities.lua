
--=============================================================================
-- FILE: init.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.setup()
  require('myutil.autocmds').setup()
  require('myutil.commands').setup()
end

return M
