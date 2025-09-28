local M = {}

-- auto indent start insert
function M.indent_with_i(command)
  if #vim.fn.getline('.') == 0 then
    return command .. 'cc'
  else
    return command .. 'i'
  end
end

-- gJで空白を削除する
function M.join_space_less()
  local last_search = vim.fn.getreg('/')
  vim.cmd('normal! gJ')
  local original_view = vim.fn.winsaveview()
  local col = vim.fn.col('.')
  local pattern = '\\%' .. col .. 'c\\s\\+'
  vim.cmd('silent! s/' .. pattern .. '//e')
  vim.cmd('nohlsearch')
  vim.fn.setreg('/', last_search)
  vim.fn.winrestview(original_view)
end

-- vimrcをスペースドットで更新
function M.reload_vimrc()
  vim.cmd(string.format('source %s', vim.env.MYVIMRC))
  if vim.fn.has('gui_running') == 1 then
    vim.cmd(string.format('source %s', vim.env.MYGVIMRC))
  end
  vim.cmd('redraw')
  print(string.format('.vimrc/.gvimrc has reloaded (%s).', vim.fn.strftime('%c')))
end

-- macro visual selection ---------------------
function M.execute_macro_visual_range()
  print('@' .. vim.fn.getcmdline())
  local ch = vim.fn.getchar()
  if type(ch) == 'string' then
    ch = ch:byte()
  end
  -- `normal`を`normal!`に変更
  vim.cmd("'<,'>normal! @" .. vim.fn.nr2char(ch))
end

function M.ctrl_u()
  local cmdline_before = vim.fn.getcmdline()

  if vim.fn.getcmdpos() <= 1 then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes('<C-U>', true, false, true),
      'n',
      false
    )
    return
  end

  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes('<C-U>', true, false, true),
    'n',
    false
  )

  vim.defer_fn(function()
    local cmdline_after = vim.fn.getcmdline()
    local removed_text = cmdline_before:sub(1, #cmdline_before - #cmdline_after)
    vim.fn.setreg('-', removed_text)
  end, 0)
end

function M.ctrl_w()
  local cmdline_before = vim.fn.getcmdline()
  local cmdpos_before = vim.fn.getcmdpos()

  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes('<C-W>', true, false, true),
    'n',
    false
  )

  vim.defer_fn(function()
    local cmdline_after = vim.fn.getcmdline()
    local cmdpos_after = vim.fn.getcmdpos()

    if cmdline_before == cmdline_after then
      return
    end

    local removed_text = cmdline_before:sub(cmdpos_after, cmdpos_before - 1)

    vim.fn.setreg('-', removed_text)
  end, 0) -- 0ms遅延（つまり即時実行）
end

function M.ctrl_k()
  local cmdline = vim.fn.getcmdline()
  local cmdpos = vim.fn.getcmdpos() -- 1-basedのバイト位置

  local removed_text = cmdline:sub(cmdpos)

  if #removed_text > 0 then
    vim.fn.setreg('-', removed_text)
  end

  local new_cmdline = cmdline:sub(1, cmdpos - 1)
  vim.fn.setcmdline(new_cmdline)
end

-- search google ---------------------
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  -- vim.fn.getline can return a string when start_pos[2] == end_pos[2]; ensure we always have a table
  if type(lines) == 'string' then
    lines = { lines }
  end
  if #lines == 0 then
    return ''
  end
  lines[#lines] = lines[#lines]:sub(1, end_pos[3] - (vim.o.selection == 'inclusive' and 1 or 2))
  lines[1] = lines[1]:sub(start_pos[3])
  return table.concat(lines, '\n')
end

function M.google_search()
  local vtext = get_visual_selection()
  local word = vim.fn.expand('<cword>')
  if vtext ~= '' then
    word = vtext
  end
  local query = 'http://www.google.co.jp/search?num=100&q=' .. word
  -- Use shellescape to avoid embedding unescaped characters in the shell command
  vim.fn.system('google-chrome-stable ' .. vim.fn.shellescape(query) .. ' 2> /dev/null &')
end

function M.google_open()
  local vtext = get_visual_selection()
  local url
  if vtext:match('^http') then
    url = vtext
  else
    url = "https://github.com/" .. vtext
  end
  vim.fn.system('google-chrome-stable ' .. vim.fn.shellescape(url) .. ' 2> /dev/null &')
end

-- fold ---------------------
function M.custom_fold_text()
  local foldstart = vim.v.foldstart
  local foldend = vim.v.foldend
  local foldlevel = vim.v.foldlevel

  local fs = foldstart
  while vim.fn.getline(fs):match('^\\s*$') do
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

-- vim command capture ---------------------
local function capture(cmd)
  return vim.fn.execute(cmd)
end

function M.cmd_capture(args)
  local out = capture(table.concat(args.fargs, ' '))
  -- ensure we pass a list of lines to nvim_put (split on newlines)
  local lines = vim.split(out, '\n')
  vim.cmd('new')
  vim.api.nvim_put(lines, 'c', true, true)
  vim.cmd('1,2delete _')
end

-- toggle function ---------------------
local function count_and_highlight_word()
  local original_view = vim.fn.winsaveview()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.fn.winrestview(original_view)
    return
  end
  local pattern = vim.fn.escape(word, [=[/\\.*$^[]%()]=])
  vim.fn.setreg('/', pattern)
  vim.v.hlsearch = 1 -- 明示的にハイライトをONにする
  vim.cmd('silent %s///gn')

  vim.fn.winrestview(original_view)
end

function M.hl_text_toggle()
  if vim.v.hlsearch ~= 0 then
    vim.cmd('noh')
  else
    count_and_highlight_word()
  end
end

-- auto mkdir ---------------------
function M.auto_mkdir(dir, force)
  if not vim.fn.isdirectory(dir) and (force or vim.fn.input(string.format('"%s" does not exist. Create? [y/N]', dir)):match('^[yY]')) then
    vim.fn.mkdir(dir, 'p')
  end
end

-- local setting ---------------------
function M.vimrc_local(loc)
  local files = vim.fn.findfile('.vimrc.local', vim.fn.escape(loc, ' ') .. ';', -1)
  -- findfile may return a single string when only one file is found; normalize to a table
  if type(files) == 'string' then
    files = { files }
  end
  for _, file in ipairs(vim.fn.reverse(files)) do
    if vim.fn.filereadable(file) == 1 then
      vim.cmd('source ' .. file)
    end
  end
end

-- remove top new line and end line yank ---------------------
function M.yank_remove_line()
  local tmp = vim.fn.getreg('"')
  -- use vim.fn.substitute to apply Vim regex patterns correctly
  local yank = vim.fn.substitute(tmp, '^\\_s\\+', '', 'g')
  yank = vim.fn.substitute(yank, '\\_s\\_$', '', 'g')
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

-- insert leave ime off ---------------------
function M.fcitx2en()
  local status = vim.fn.system('fcitx5-remote')
  if type(status) == 'string' then
    status = status:match('%d+')
  end
  local n = tonumber(status)
  if n == 2 then
    vim.fn.system('fcitx5-remote -c')
  end
end

-- delete line enhance ---------------------
function M.remove_line_brank(count)
  local cnt = tonumber(count) or vim.v.count1 or 1
  for i = 1, cnt do
    local line = vim.fn.getline('.')
    if line == '' or line:match('^%s*$') then
      vim.cmd('silent! normal! "_dd')
    else
      vim.cmd('silent! normal! dd')
    end
  end
end

function M.remove_line_brank_all(count)
  local cnt = tonumber(count) or vim.v.count1 or 1
  for i = 1, cnt do
    local line = vim.fn.getline('.')
    if line == '' or line:match('^%s*$') then
      vim.cmd('silent! normal! "_dd')
    else
      vim.cmd('silent! normal! dd')
    end
  end
  while true do
    local line = vim.fn.getline('.')
    if line == '' then
      vim.cmd('silent! normal! "_dd')
    else
      break
    end
  end
end

return M
