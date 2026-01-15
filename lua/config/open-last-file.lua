local uv = vim.uv or vim.loop

local function should_auto_reopen()
  local argc = vim.fn.argc()
  if argc == 0 then return true end
  return argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
end

local function startup_path()
  if vim.fn.argc() == 1 then
    local arg0 = vim.fn.argv(0)
    if arg0 and vim.fn.isdirectory(arg0) == 1 then
      return arg0
    end
  end
  return (uv.cwd and uv.cwd()) or vim.fn.getcwd()
end

local function find_git_root_path(path)
  path = path or (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  if not (vim.fs and vim.fs.root) then return nil end
  return vim.fs.root(path, { '.git' })
end

local function get_state_file_path(root_path)
  local root_dir = vim.fn.fnamemodify(root_path, ':t')
  return vim.fn.stdpath('state') .. ('/last-file/%s-lastfile.txt'):format(root_dir)
end

local function is_ignored(path)
  if not path or path == '' then return true end
  if path:match('^%w+://') then return true end
  if path:match('/%.git/') or path:match('/%.git$') then return true end
  return false
end

local function save_last_file()
  if vim.bo.buftype ~= '' then return end

  local path = vim.api.nvim_buf_get_name(0)
  if is_ignored(path) then return end

  local stat = uv.fs_stat(path)
  if not (stat and stat.type == 'file') then return end

  local git_root_path = find_git_root_path(path)
  if not git_root_path then return end
  pcall(vim.fn.writefile, { path }, get_state_file_path(git_root_path))
end

local function open_last_file()
  if not should_auto_reopen() then return false end

  local git_root_path = find_git_root_path(startup_path())
  if not git_root_path then return end

  local ok, lines = pcall(vim.fn.readfile, get_state_file_path(git_root_path))
  local path = ok and lines and lines[1] or nil
  if is_ignored(path) then return false end

  local stat = uv.fs_stat(path)
  if not (stat and stat.type == 'file') then return false end

  vim.cmd({ cmd = 'edit', args = { path } })
  return true
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
  callback = save_last_file,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    if vim.bo.buftype ~= '' then return end
    if vim.fn.line('.') > 1 or vim.fn.col('.') > 1 then return end

    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local last_line = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= last_line then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(open_last_file)
  end,
})

vim.api.nvim_create_user_command('OpenLastFile', open_last_file, {})
