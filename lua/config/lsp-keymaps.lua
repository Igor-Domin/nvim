local format_group = vim.api.nvim_create_augroup('user_lsp_format', {})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR><cmd>cclose<CR>', {
      buffer = true,
      silent = true,
    })

    vim.keymap.set('n', 'q', '<cmd>cclose<CR>', {
      buffer = true,
      silent = true,
    })
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', {}),
  callback = function(args)
    local buf_nr = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local opts = { buffer = buf_nr, remap = false }

    if client:supports_method('textDocument/implementation') then
      vim.keymap.set('n', 'K', function()
        vim.lsp.buf.hover({ border = 'double', max_width = 100, max_height = 60, focusable = true })
      end, opts)

      vim.keymap.set('n', '<leader>fd', vim.lsp.buf.definition, opts)

      vim.keymap.set('n', '<leader>fr', vim.lsp.buf.references, opts)

      vim.keymap.set('n', '<leader>fS', function()
        vim.ui.input({ prompt = 'Symbol: ' }, function(query)
          if query and query ~= '' then
            vim.lsp.buf.workspace_symbol(query)
          end
        end)
      end, opts)

      vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)

      vim.keymap.set('n', '<leader>re', vim.lsp.buf.rename, opts)

      -- Diagnostics --

      vim.keymap.set('n', '<C-d>', vim.diagnostic.open_float, opts)

      vim.keymap.set('n', '[d', function()
        vim.diagnostic.goto_prev()
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set('n', ']d', function()
        vim.diagnostic.goto_next()
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set('n', '[D', function()
        vim.diagnostic.jump({
          count = -math.huge,
          wrap = false,
        })
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set('n', ']D', function()
        vim.diagnostic.jump({
          count = math.huge,
          wrap = false,
        })
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)


      -- Code Actions --

      vim.keymap.set('n', '<leader>c', function()
        vim.lsp.buf.code_action({}, opts)
      end)

      local function apply_hlint(pattern)
        local last_line = vim.api.nvim_buf_line_count(buf_nr)

        local diagnostics = vim.tbl_map(function(diagnostic)
          return diagnostic.user_data.lsp
        end, vim.diagnostic.get(buf_nr))

        vim.lsp.buf.code_action({
          range = {
            start = { 1, 0 },
            ['end'] = { last_line, 0 },
          },
          context = { diagnostics = diagnostics },
          filter = function(action)
            return action.title:match(pattern) ~= nil
          end,
          apply = true,
        })
      end

      vim.keymap.set('n', '<leader>cs', function()
        apply_hlint('^Apply hint')
      end)

      vim.keymap.set('n', '<leader>ca', function()
        apply_hlint('^Apply all')
      end)
    end

    if client:supports_method('textDocument/completion') then
      -- CTRL + p = previous item
      -- CTRL + n = next item
      -- Use CTRL-Y to select an item.
      vim.keymap.set('i', '<C-Space>', function()
        vim.lsp.completion.get()
      end)

      vim.keymap.set('i', '<Tab>', function()
        return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
      end, { expr = true })

      vim.keymap.set('i', '<S-Tab>', function()
        return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
      end, { expr = true })

      vim.keymap.set('i', '<CR>', function()
        return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
      end, { expr = true })

      vim.keymap.set('i', '<Esc>', function()
        if vim.fn.pumvisible() == 1 then
          return '<C-e><Esc>'
        end
        return '<Esc>'
      end, { expr = true })

      -- Completion UX: show a menu without auto-select/insert.
      vim.opt.completeopt = { 'menuone', 'popup', 'noinsert', 'noselect', }

      vim.o.pumborder = 'rounded'
      vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'PmenuBorder', { bg = 'NONE', fg = "#aa12bb" })
      vim.api.nvim_set_hl(0, 'PmenuSel', { fg = 'NONE', bg = '#5555ff', bold = true })

      -- Optional: trigger autocompletion on EVERY keypress. May be slow!
      local chars = {}
      for i = 32, 126 do
        chars[#chars + 1] = string.char(i)
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars

      vim.lsp.completion.enable(true, client.id, buf_nr, {
        autotrigger = true,
        convert = function(item)
          return { abbr = (item.label or ''):gsub('%b()', '') }
        end,
      })
    end


    -- Auto-format ('lint') on save --
    -- Usually not needed if server supports 'textDocument/willSaveWaitUntil'.
    if not client:supports_method('textDocument/willSaveWaitUntil')
        and client:supports_method('textDocument/formatting') then
      -- Replace any existing format-on-save autocmd for this buffer.
      vim.api.nvim_clear_autocmds({ group = format_group, buffer = buf_nr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = format_group,
        buffer = buf_nr,
        desc = 'LSP format before save',
        callback = function()
          -- Block save until formatting completes so edits apply before write.
          vim.lsp.buf.format({
            bufnr = buf_nr,
            timeout_ms = 1000,
            async = false,
          })
        end,
      })
    end
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<leader>f', function()
        vim.lsp.buf.format({
          bufnr = buf_nr,
          async = false,
        })
      end, { buffer = buf_nr })
    end
  end,
})
