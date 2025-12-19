--- Haskell ---

local hls = require('lsp.hls')

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user-haskell-lsp', {}),
  pattern = { 'haskell', 'lhaskell' },
  callback = function(args)
    hls.start(args.buf)
  end,
})


--- Lua ---

local lua_ls = require('lsp.lua_ls')

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user-lua-lsp', {}),
  pattern = { 'lua' },
  callback = function(args)
    lua_ls.start(args.buf)
  end,
})


--- Markdown ---

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})


--- Other configs ---

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = {
    -- severity = { min = vim.diagnostic.severity.WARN },
    prefix = "▎ ",
    format = function(d)
      return d.message:gsub("\n.*", "")
    end,
  },
  underline = true,
  signs = true,
  update_in_insert = false,
  severity_sort = true,
  -- Border
  float = {
    border = "double",
    source = "if_many",
    header = "",
    prefix = "",
  },
})

-- vim.api.nvim_create_autocmd("CursorHold", {
--   callback = function()
--     vim.diagnostic.open_float()
--   end,
-- })
