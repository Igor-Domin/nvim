local languages = {
  'haskell', 'scala', 'java', 'python', 'sql', 'help', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline'
}
return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate',
  config = function()
    -- replicate `ensure_installed`, runs asynchronously, skips existing languages
    require('nvim-treesitter').install(languages)

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter.setup', { clear = true }),
      callback = function(args)
        local buf = args.buf
        local filetype = args.match

        -- you need some mechanism to avoid running on buffers that do not
        -- correspond to a language (like oil.nvim buffers), this implementation
        -- checks if a parser exists for the current language
        local language = vim.treesitter.language.get_lang(filetype) or filetype
        local ok = pcall(vim.treesitter.start, buf, language)
        if not ok then
          return
        end

        -- replicate `fold = { enable = true }`
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo.foldenable = false

        -- replicate `indent = { enable = true }`
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        -- if filetype == 'haskell' then
        --  vim.bo[buf].indentexpr = ''
        -- end
      end,
    })
  end,
}
