--=============================================================================
-- FILE: misc.lua
-- AUTHOR: aikawa
-- License: MIT license
--=============================================================================

local M = {}

function M.set_default(var, val, ...)
  if vim.g[var] == nil or type(vim.g[var]) ~= type(val) then
    local alternate_var = select(1, ...)
    if alternate_var ~= nil and vim.g[alternate_var] ~= nil then
      vim.g[var] = vim.g[alternate_var]
    else
      vim.g[var] = val
    end
  end
end

function M.indent_with_i(command)
  if #vim.fn.getline('.') == 0 then
    return command .. 'cc'
  else
    return command .. 'i'
  end
end

function M.join_space_less()
  vim.cmd('normal! gj')
  if vim.fn.matchstr(vim.fn.getline('.'), '\%' .. vim.fn.col('.') .. 'c.'):match('\s') then
    vim.cmd('normal! dw')
  end
end

function M.reload_vimrc()
  vim.cmd(string.format('source %s', vim.env.MYVIMRC))
  if vim.fn.has('gui_running') == 1 then
    vim.cmd(string.format('source %s', vim.env.MYGVIMRC))
  end
  vim.cmd('redraw')
  print(string.format('.vimrc/.gvimrc has reloaded (%s).', vim.fn.strftime('%c')))
end

function M.execute_macro_visual_range()
  print('@' .. vim.fn.getcmdline())
  vim.cmd("'<,'>normal @" .. vim.fn.nr2char(vim.fn.getchar()))
end

function M.ctrl_u()
  if vim.fn.getcmdpos() > 1 then
    vim.fn.setreg('-', vim.fn.getcmdline():sub(1, vim.fn.getcmdpos() - 2))
  end
  return "\<C-U>"
end

local cmdline_before_ctrl_w = ''
function M.ctrl_w_before()
  cmdline_before_ctrl_w = vim.fn.getcmdpos() > 1 and vim.fn.getcmdline() or ''
  return "\<C-W>"
end

function M.ctrl_w_after()
  if #cmdline_before_ctrl_w > 0 then
    local original_len = #cmdline_before_ctrl_w
    local current_len = #vim.fn.getcmdline()
    local removed = cmdline_before_ctrl_w:sub(vim.fn.getcmdpos(), vim.fn.getcmdpos() + (original_len - current_len) -1)
    vim.fn.setreg('-', removed)
  end
  return ''
end

local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  if #lines == 0 then
    return ''
  end
  lines[#lines] = lines[#lines]:sub(1, end_pos[3] - (vim.o.selection == 'inclusive' and 1 or 2))
  lines[1] = lines[1]:sub(start_pos[3])
  return table.concat(lines, '\n')
end

function M.help_override()
  local vtext = get_visual_selection()
  local word = vim.fn.expand('<cword>')
  if vtext ~= '' then
    word = vtext
  end
  local success, _ = pcall(vim.cmd, 'silent help ' .. word)
  if not success then
    print(word .. ' is no help text')
  end
end

function M.google_search()
  local vtext = get_visual_selection()
  local word = vim.fn.expand('<cword>')
  if vtext ~= '' then
    word = vtext
  end
  vim.fn.system(string.format('google-chrome-stable "%s" 2> /dev/null &', 'http://www.google.co.jp/search?num=100&q=' .. word))
end

function M.google_open()
  local vtext = get_visual_selection()
  local url
  if vtext:match('^http') then
    url = vtext
  else
    url = "https://github.com/" .. vtext
  end
  vim.fn.system(string.format('google-chrome-stable "%s" 2> /dev/null &', url))
end

return M
