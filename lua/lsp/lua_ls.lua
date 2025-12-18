local M = {}

local root_markers = {
  '.luarc.json',
  '.luarc.jsonc',
  '.stylua.toml',
  'stylua.toml',
  '.git',
}

local function find_root(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  if fname == '' then
    return nil
  end

  if vim.fs.root then
    local root = vim.fs.root(fname, root_markers)
    if root then
      return root
    end
  end

  local dir = vim.fs.dirname(fname)
  local marker = vim.fs.find(root_markers, { path = dir, upward = true })[1]
  if marker then
    return vim.fs.dirname(marker)
  end

  return dir
end

local function find_server()
  local exe = vim.fn.exepath('lua-language-server')
  if exe ~= '' then
    return exe
  end
  return nil
end

function M.start(bufnr)
  local cmd = find_server()
  if not cmd then
    vim.notify('Lua LS not found on PATH (lua-language-server)', vim.log.levels.WARN)
    return
  end

  local root_dir = find_root(bufnr)
  if not root_dir then
    return
  end

  vim.lsp.start({
    name = 'lua-language-server',
    cmd = { cmd },
    root_dir = root_dir,
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT'
        },
        diagnostics = { globals = { 'vim' } },
        workspace = { checkThirdParty = false },
        completion = { callSnippet = 'Replace' },
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
