local format_group = vim.api.nvim_create_augroup('user_lsp_format', {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR><cmd>cclose<CR>", {
      buffer = true,
      silent = true,
    })

    vim.keymap.set("n", "q", "<cmd>cclose<CR>", {
      buffer = true,
      silent = true,
    })
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', {}),
  callback = function(args)
    local bufnr = args.buf
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local opts = { buffer = bufnr, remap = false, }

    if client:supports_method('textDocument/implementation') then
      vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover({ border = 'double', max_width = 100, max_height = 60, focusable = true })
      end, opts)

      vim.keymap.set("n", "<leader>fd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "<leader>fr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>fs", vim.lsp.buf.workspace_symbol, opts)
      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

      vim.keymap.set("n", "<leader>re", vim.lsp.buf.rename, opts)

      --- Diagnostics ---

      vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

      vim.keymap.set("n", "[d", function()
        vim.diagnostic.goto_prev()
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.goto_next()
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set("n", "[D", function()
        vim.diagnostic.jump({
          count = -math.huge,
          wrap = false,
        })
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)
      vim.keymap.set("n", "]D", function()
        vim.diagnostic.jump({
          count = math.huge,
          wrap = false,
        })
        vim.schedule(function()
          vim.diagnostic.open_float()
        end)
      end, opts)


      --- Code Actions ---

      vim.keymap.set("n", "<leader>c", function()
        vim.lsp.buf.code_action({}, opts)
      end)

      local function apply_hlint(pattern)
        local last_line = vim.api.nvim_buf_line_count(bufnr)

        local diagnostics = vim.tbl_map(function(diagnostic)
          return diagnostic.user_data.lsp
        end, vim.diagnostic.get(bufnr))

        vim.lsp.buf.code_action({
          range = {
            start = { 1, 0 },
            ["end"] = { last_line, 0 },
          },
          context = { diagnostics = diagnostics },
          filter = function(action)
            return action.title:match(pattern) ~= nil
          end,
          apply = true,
        })
      end

      vim.keymap.set("n", "<leader>cs", function()
        apply_hlint("^Apply hint")
      end)

      vim.keymap.set("n", "<leader>ca", function()
        apply_hlint("^Apply all")
      end)
    end

    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    if client:supports_method('textDocument/completion') then
      -- Use CTRL-space to trigger LSP completion.
      -- CTRL + p = previous item
      -- CTRL + n = next item
      -- Use CTRL-Y to select an item. |complete_CTRL-Y|
      vim.keymap.set('i', '<C-Space>', function()
        vim.lsp.completion.get()
      end)

      -- Completion UX: show a menu without auto-select/insert.
      vim.opt.completeopt = { 'menuone', 'noselect' }
      pcall(function() vim.opt.completeopt:append('popup') end)

      -- Optional: trigger autocompletion on EVERY keypress. May be slow!
      local chars = {}
      for i = 32, 126 do
        chars[#chars + 1] = string.char(i)
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars

      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,
        convert = function(item)
          return { abbr = (item.label or ''):gsub('%b()', '') }
        end,
      })
    end


    -- Auto-format ("lint") on save.
    -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
    if not client:supports_method('textDocument/willSaveWaitUntil')
        and client:supports_method('textDocument/formatting') then
      -- Replace any existing format-on-save autocmd for this buffer.
      vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = format_group,
        buffer = bufnr,
        desc = 'LSP format before save',
        callback = function()
          -- Block save until formatting completes so edits apply before write.
          vim.lsp.buf.format({
            bufnr = bufnr,
            timeout_ms = 1000,
            async = false,
          })
        end,
      })
    end
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', "<leader>f", function()
        vim.lsp.buf.format({
          bufnr = bufnr,
          async = false,
        })
      end, { buffer = bufnr })
    end
  end,
})
