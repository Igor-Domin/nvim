local M = {}

local root_markers = {
	'hie.yaml',
	'stack.yaml',
	'cabal.project',
	'package.yaml',
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

	local current = dir
	while current do
		for name, type_ in vim.fs.dir(current) do
			if type_ == 'file' and name:match('%.cabal$') then
				return current
			end
		end
		local parent = vim.fs.dirname(current)
		if not parent or parent == current then
			break
		end
		current = parent
	end

	return dir
end

local function find_hls()
	local wrapper = vim.fn.exepath('haskell-language-server-wrapper')
	if wrapper ~= '' then
		return wrapper
	end

	local hls = vim.fn.exepath('haskell-language-server')
	if hls ~= '' then
		return hls
	end

	return nil
end

function M.start(bufnr)
	local cmd = find_hls()
	if not cmd then
		vim.notify('HLS: haskell-language-server not found in PATH', vim.log.levels.ERROR)
		return
	end

	local root_dir = find_root(bufnr)
	if not root_dir then
		if vim.api.nvim_buf_get_name(bufnr) ~= '' then
			vim.notify('HLS: could not find project root', vim.log.levels.WARN)
		end
		return
	end

	vim.lsp.start({
		name = 'haskell-language-server',
		cmd = { cmd, '--lsp' },
		root_dir = root_dir,
		settings = {
			haskell = {
				formattingProvider = 'ormolu',
				cabalFormattingProvider = 'cabal-fmt',
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
