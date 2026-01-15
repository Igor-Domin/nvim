local M = {}

local root_markers = { 'hie.yaml', 'stack.yaml', 'cabal.project', 'package.yaml', '.git' }

local function find_hls_cmd()
  local wrapper = vim.fn.exepath('haskell-language-server-wrapper')
  if wrapper ~= '' then return wrapper end

  local hls = vim.fn.exepath('haskell-language-server')
  if hls ~= '' then return hls end

  return nil
end

local function find_root_path(buf_nr)
  local path = vim.api.nvim_buf_get_name(buf_nr)
  if path == '' then return nil end

  local root_path = vim.fs.root(path, root_markers)
  if root_path then return root_path end

  local cabal_file = vim.fs.find(function(name)
    return name:match('%.cabal$') ~= nil
  end, {
    path = vim.fs.dirname(path),
    upward = true,
  })[1]

  if cabal_file then
    return vim.fs.dirname(cabal_file)
  end

  return vim.fs.dirname(path)
end

function M.start(buf_nr)
  local cmd = find_hls_cmd()
  if not cmd then
    vim.notify('HLS: not found in PATH (haskell-language-server-wrapper / haskell-language-server)',
      vim.log.levels.ERROR)
    return
  end

  local root_path = find_root_path(buf_nr)
  if not root_path then return end

  vim.lsp.start({
    name = 'haskell-language-server',
    cmd = { cmd, '--lsp' },
    root_dir = root_path,
    settings = {
      haskell = {
        formattingProvider = 'ormolu',
        cabalFormattingProvider = 'cabal-fmt',
      },
    },
  }, {
    bufnr = buf_nr,
    reuse_client = function(client, config)
      return client.name == config.name
          and client.config
          and client.config.root_dir == config.root_dir
    end,
  })
end

return M
