local uv = vim.uv or vim.loop
local statefile = vim.fn.stdpath("state") .. "/lastfile.txt"

local last_saved_path

local function is_file(path)
  if not path or path == "" then return false end
  if path:match("^%w+://") then return false end
  local st = uv.fs_stat(path)
  return st and st.type == "file"
end

local function save_lastfile()
  if vim.bo.buftype ~= "" then return end

  local path = vim.api.nvim_buf_get_name(0)
  if not is_file(path) then return end
  if path == last_saved_path then return end

  last_saved_path = path
  pcall(vim.fn.writefile, { path }, statefile)
end

local function should_autoreopen()
  local argc = vim.fn.argc()
  if argc == 0 then return true end
  return argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
end

local function open_lastfile()
  if not should_autoreopen() then return false end

  local ok, lines = pcall(vim.fn.readfile, statefile)
  local path = (ok and lines and lines[1]) or nil
  if not is_file(path) then return false end

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
    -- vim.defer_fn(open_lastfile, 50)
    vim.schedule(open_lastfile)
  end,
})

vim.api.nvim_create_user_command("OpenLastFile", open_lastfile, {})
