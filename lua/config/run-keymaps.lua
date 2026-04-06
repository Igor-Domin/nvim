local function show_result(output, time_output)
  local user_time = time_output:match('([%d.]+)s user')
  local sys_time = time_output:match('([%d.]+)s system')
  local real_time = time_output:match('([%d.]+) total')

  vim.api.nvim_echo({
    { 'Output:\n\n\n',           'SpellRare' },
    { output .. '\n\n\n',        'Normal' },
    { 'Time: ',                  'Type' },
    { 'real ',                   'Constant' },
    { (real_time or '?') .. 's', 'Type' },
    { ' | ',                     'PreProc' },
    { 'user ',                   'Constant' },
    { (user_time or '?') .. 's', 'Type' },
    { ' | ',                     'PreProc' },
    { 'sys ',                    'Constant' },
    { (sys_time or '?') .. 's',  'Type' },
  }, true, {})
end

local function run(shell_cmd, cwd, display_output)
  vim.system(
    { '/bin/zsh', '-c', shell_cmd },
    { text = true, cwd = cwd },
    function(result)
      vim.schedule(function()
        local output = vim.trim(result.stdout or '')
        local time_output = vim.trim(result.stderr or '')

        if result.code ~= 0 then
          print('Failed:\n\n' .. time_output)
          return
        end

        if display_output then
          time_output = time_output:match('[^\n]+%s+total$') or ''
        end

        show_result(output, time_output)
      end)
    end
  )
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'haskell',
  callback = function()
    vim.keymap.set('n', '<leader>cr', function()
      vim.cmd('write')
      local file_name = vim.fn.expand('%:t')
      local path = vim.fn.expand('%:p:h')
      run(string.format('time runghc %s', file_name), path)
    end, { buffer = true, desc = 'Haskell: run (interpreted)' })

    vim.keymap.set('n', '<leader>cb', function()
      vim.cmd('write')
      local file_name = vim.fn.expand('%:t')
      local bin_name = vim.fn.expand('%:t:r')
      local path = vim.fn.expand('%:p:h')
      run(
        string.format(
          'time (ghc %s -O2 -o %s > /dev/null && rm -f %s.o %s.hi && ./%s)',
          file_name, bin_name, bin_name, bin_name, bin_name
        ),
        path
      )
    end, { buffer = true, desc = 'Haskell: build + run (compiled)' })

    vim.keymap.set('n', '<leader>cR', function()
      local bin_name = vim.fn.expand('%:t:r')
      local path = vim.fn.expand('%:p:h')
      run(string.format('time ./%s', bin_name), path)
    end, { buffer = true, desc = 'Haskell: run (compiled)' })
  end,
})
