local namespace_id = vim.api.nvim_create_namespace('hunt-messages')
local buf_name = 'HuntMessages'

local function ensure_buf()
  local buf_nr = vim.g._printlog_buf_nr
  if buf_nr and vim.api.nvim_buf_is_valid(buf_nr) then return buf_nr end

  buf_nr = vim.api.nvim_create_buf(false, true)
  vim.bo[buf_nr].buftype = 'nofile'
  vim.bo[buf_nr].bufhidden = 'hide'
  vim.bo[buf_nr].swapfile = false
  vim.bo[buf_nr].modifiable = false
  vim.api.nvim_buf_set_name(buf_nr, buf_name)

  vim.g._printlog_buf_nr = buf_nr
  return buf_nr
end

vim.api.nvim_create_user_command('HuntMessages', function()
  local buf_nr = ensure_buf()
  vim.cmd('new')
  vim.api.nvim_win_set_buf(0, buf_nr)
end, {})

vim.api.nvim_create_user_command('Messages', function()
  local output = vim.api.nvim_exec2('messages', { output = true }).output or ''
  vim.cmd('new')
  local buf_nr = vim.api.nvim_get_current_buf()
  vim.bo[buf_nr].buftype = 'nofile'
  vim.bo[buf_nr].bufhidden = 'wipe'
  vim.bo[buf_nr].swapfile = false
  vim.api.nvim_buf_set_name(buf_nr, 'Messages')
  vim.api.nvim_buf_set_lines(buf_nr, 0, -1, false, vim.split(output, '\n', { plain = true }))
end, {})

local function level_name(level)
  return ({
    [vim.log.levels.TRACE] = 'TRACE',
    [vim.log.levels.DEBUG] = 'DEBUG',
    [vim.log.levels.INFO] = 'INFO',
    [vim.log.levels.WARN] = 'WARN',
    [vim.log.levels.ERROR] = 'ERROR',
  })[level] or tostring(level)
end

local function level_hl(level)
  return ({
    [vim.log.levels.TRACE] = 'DiagnosticHint',
    [vim.log.levels.DEBUG] = 'DiagnosticHint',
    [vim.log.levels.INFO] = 'DiagnosticInfo',
    [vim.log.levels.WARN] = 'DiagnosticWarn',
    [vim.log.levels.ERROR] = 'DiagnosticError',
  })[level] or 'Normal'
end

local function append(level, msg)
  local buf_nr = ensure_buf()
  local hl_group = level_hl(level)
  local tag = ('[%s] '):format(level_name(level))

  local text = (type(msg) == 'string') and msg or vim.inspect(msg)
  local lines = vim.split(text, '\n', { plain = true })
  if #lines == 0 then lines = { '' } end

  local start_line = vim.api.nvim_buf_line_count(buf_nr)

  local out_lines = {}
  for i, l in ipairs(lines) do
    out_lines[i] = (i == 1) and (tag .. l) or (string.rep(' ', #tag) .. l)
  end

  vim.bo[buf_nr].modifiable = true
  vim.api.nvim_buf_set_lines(buf_nr, -1, -1, false, out_lines)
  vim.bo[buf_nr].modifiable = false

  for i = 0, (#out_lines - 1) do
    local line_text = out_lines[i + 1] or ''
    vim.api.nvim_buf_set_extmark(buf_nr, namespace_id, start_line + i, 0, {
      end_col = #line_text,
      hl_group = hl_group,
      hl_eol = true,
      hl_mode = 'replace',
      priority = 1000,
    })
  end
end

-- Overrides --

do
  local old_print = _G.print
  _G.print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do
      local v = select(i, ...)
      parts[#parts + 1] = (type(v) == 'string') and v or vim.inspect(v)
    end
    append(vim.log.levels.INFO, table.concat(parts, ' '))
    return old_print(...)
  end
end

do
  local old_notify = vim.notify
  vim.notify = function(msg, level, opts)
    level = level or vim.log.levels.INFO
    append(level, msg)

    if level == vim.log.levels.ERROR then
      vim.schedule(function() pcall(vim.cmd, 'HuntMessages') end)
      return
    end
    return old_notify(msg, level, opts)
  end
end
