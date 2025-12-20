local M = {}

local root_markers = { "hie.yaml", "stack.yaml", "cabal.project", "package.yaml", ".git" }

local function find_hls_cmd()
  local wrapper = vim.fn.exepath("haskell-language-server-wrapper")
  if wrapper ~= "" then return wrapper end

  local hls = vim.fn.exepath("haskell-language-server")
  if hls ~= "" then return hls end

  return nil
end

local function find_root_dir(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return nil end

  local root = vim.fs.root(file, root_markers)
  if root then return root end

  local cabal_file = vim.fs.find(function(name)
    return name:match("%.cabal$") ~= nil
  end, {
    path = vim.fs.dirname(file),
    upward = true,
  })[1]

  if cabal_file then
    return vim.fs.dirname(cabal_file)
  end

  return vim.fs.dirname(file)
end

function M.start(bufnr)
  local cmd = find_hls_cmd()
  if not cmd then
    vim.notify("HLS: not found in PATH (haskell-language-server-wrapper / haskell-language-server)",
      vim.log.levels.ERROR)
    return
  end

  local root_dir = find_root_dir(bufnr)
  if not root_dir then return end

  vim.lsp.start({
    name = "haskell-language-server",
    cmd = { cmd, "--lsp" },
    root_dir = root_dir,
    settings = {
      haskell = {
        formattingProvider = "ormolu",
        cabalFormattingProvider = "cabal-fmt",
      },
    },
  }, {
    bufnr = bufnr,
    reuse_client = function(client, config)
      return client.name == config.name
          and client.config
          and client.config.root_dir == config.root_dir
    end,
  })
end

return M
