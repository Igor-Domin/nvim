local M = {}

local root_markers = {
  ".luarc.json",
  ".luarc.jsonc",
  ".stylua.toml",
  "stylua.toml",
  ".git",
}

local function find_lua_ls_cmd()
  local exe = vim.fn.exepath("lua-language-server")
  return (exe ~= "") and exe or nil
end

local function find_root_dir(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return nil end

  local root = vim.fs.root(file, root_markers)
  if root then return root end

  return vim.fs.dirname(file)
end

function M.start(bufnr)
  local cmd = find_lua_ls_cmd()
  if not cmd then
    vim.notify("Lua LS not found on PATH (lua-language-server)", vim.log.levels.WARN)
    return
  end

  local root_dir = find_root_dir(bufnr)
  if not root_dir then return end

  vim.lsp.start({
    name = "lua-language-server",
    cmd = { cmd },
    root_dir = root_dir,
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
        completion = { callSnippet = "Replace" },
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
