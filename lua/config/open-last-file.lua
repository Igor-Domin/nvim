local uv = vim.uv or vim.loop

local function should_autoreopen()
  local argc = vim.fn.argc()
  if argc == 0 then return true end
  return argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
end

local function startup_root()
  if vim.fn.argc() == 1 then
    local a0 = vim.fn.argv(0)
    if a0 and vim.fn.isdirectory(a0) == 1 then
      return a0
    end
  end
  return (uv.cwd and uv.cwd()) or vim.fn.getcwd()
end

local function project_root(path)
  path = path or (uv.cwd and uv.cwd()) or vim.fn.getcwd()
  return (vim.fs and vim.fs.root and vim.fs.root(path, { ".git" })) or path
end

local function statefile_for(root)
  local rootname = vim.fn.fnamemodify(root, ":t")
  return vim.fn.stdpath("state") .. ("/%s-lastfile.txt"):format(rootname)
end

local function is_ignored(path)
  if not path or path == "" then return true end
  if path:match("^%w+://") then return true end
  if path:match("/%.git/") or path:match("/%.git$") then return true end
  return false
end

local function save_lastfile()
  if vim.bo.buftype ~= "" then return end

  local path = vim.api.nvim_buf_get_name(0)
  if is_ignored(path) then return end

  local st = uv.fs_stat(path)
  if not (st and st.type == "file") then return end

  local root = project_root(path)
  pcall(vim.fn.writefile, { path }, statefile_for(root))
end

local function open_lastfile()
  if not should_autoreopen() then return false end

  local root = project_root(startup_root())
  local ok, lines = pcall(vim.fn.readfile, statefile_for(root))
  local path = ok and lines and lines[1] or nil
  if is_ignored(path) then return false end

  local st = uv.fs_stat(path)
  if not (st and st.type == "file") then return false end

  vim.cmd({ cmd = "edit", args = { path } })
  return true
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  callback = save_lastfile,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    if vim.bo.buftype ~= "" then return end
    if vim.fn.line(".") > 1 or vim.fn.col(".") > 1 then return end

    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local last_line = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= last_line then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(open_lastfile)
  end,
})

vim.api.nvim_create_user_command("OpenLastFile", open_lastfile, {})
