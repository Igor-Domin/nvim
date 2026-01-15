local M = {}

local root_markers = {
  '.luarc.json',
  '.luarc.jsonc',
  '.stylua.toml',
  'stylua.toml',
  '.git',
}

local function find_lua_ls_cmd()
  local exe = vim.fn.exepath('lua-language-server')
  return (exe ~= '') and exe or nil
end

local function find_root_path(buf_nr)
  local path = vim.api.nvim_buf_get_name(buf_nr)
  if path == '' then return nil end

  local root_path = vim.fs.root(path, root_markers)
  if root_path then return root_path end

  return vim.fs.dirname(path)
end

function M.start(buf_nr)
  local cmd = find_lua_ls_cmd()
  if not cmd then
    vim.notify('Lua LS not found on PATH (lua-language-server)', vim.log.levels.WARN)
    return
  end

  local root_path = find_root_path(buf_nr)
  if not root_path then return end

  vim.lsp.start({
    name = 'lua-language-server',
    cmd = { cmd },
    root_dir = root_path,
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim' } },
        workspace = { checkThirdParty = false },
        completion = { callSnippet = 'Replace' },
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
