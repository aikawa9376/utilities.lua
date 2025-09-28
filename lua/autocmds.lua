
--=============================================================================
-- FILE: autocmds.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup('myutil', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'gitcommit',
    command = 'setlocal spell',
    group = group,
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
      require('myutil.qf').qf_enhanced()
    end,
    group = group,
  })

  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*',
    callback = function()
      require('myutil.fs').auto_mkdir(vim.fn.expand('<afile>:p:h'), vim.v.cmdbang)
    end,
    group = group,
  })

  vim.api.nvim_create_autocmd({'TextYankPost', 'TextChanged', 'InsertEnter'}, {
    pattern = '*',
    callback = function()
      require('myutil.yank').yank_toggle_flag()
    end,
    group = group,
  })
end

return M
