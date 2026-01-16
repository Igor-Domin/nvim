-- Normal mode --

vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { silent = true })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { silent = true })

vim.keymap.set('n', '<leader>fe', vim.cmd.Ex)

vim.keymap.set('n', 'J', 'mzJ`z')

vim.keymap.set('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set('n', '<leader>y', '"+yy', { desc = 'Yank line to clipboard' })
vim.keymap.set('n', '<leader>Y', ':%y+<CR>', { desc = 'Yank whole file to clipboard' })

vim.keymap.set('n', '<leader>u', function() vim.cmd.UndotreeToggle() end)

vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

vim.keymap.set('n', '<leader>d', "\"_d")

-- Insert mode --

vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { silent = true })
vim.keymap.set('i', '<A-k>', '<Esc>:m .-2<CR>==gi', { silent = true })

vim.keymap.set('n', '<leader>d', '"_d')

vim.keymap.set('i', '<leader>p', '<C-r>"')
vim.keymap.set('i', '<leader>P', '<C-r>+')

-- Visual mode --

vim.keymap.set('v', '<A-j>', [[:m '>+1<CR>gv=gv]], { silent = true })
vim.keymap.set('v', '<A-k>', [[:m '<-2<CR>gv=gv]], { silent = true })

vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank selection to clipboard' })
vim.keymap.set('v', '<leader>rs', [[y:%s/\V<C-r>"/<C-r>"/gI<Left><Left><Left>]])

vim.keymap.set('v', '<leader>d', "\"_d")

vim.keymap.set('v', '<leader>p', "\"_dPp")

-- Telescope --

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>fw', function()
  telescope_builtin.grep_string({
    search = vim.fn.expand('<cword>'),
  })
end)

vim.keymap.set('n', '<leader>fa', telescope_builtin.live_grep, {})

vim.keymap.set('n', '<leader>fs', function()
  telescope_builtin.lsp_document_symbols({
    symbols = {
      'Function',
      'Method',
      'Constructor',
      'Class',
      'Interface',
      -- 'Module',
      'TypeParameter',
      'Variable',
    },
  })
end)

vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, {})

vim.keymap.set('n', '<leader>fg', function()
  local git_marker = vim.fn.finddir('.git', '.;')
  if git_marker == '' then
    print('Not a git repository. Using find_files instead.')
    require('telescope.builtin').find_files()
    return
  end
  require('telescope.builtin').git_files()
end)


-- Harpoon --

local harpoon = require('harpoon')
local harpoon_list = harpoon:list()
harpoon:setup()
vim.keymap.set('n', '<leader>q', function() harpoon.ui:toggle_quick_menu(harpoon_list) end)
vim.keymap.set('n', '<leader>a', function() harpoon_list:add() end)
vim.keymap.set('n', '<leader>A', function()
  harpoon_list:remove()
  harpoon_list:prepend()
end)

vim.keymap.set('n', '<C-h>', function() harpoon_list:select(1) end)
vim.keymap.set('n', '<C-j>', function() harpoon_list:select(2) end)
vim.keymap.set('n', '<C-k>', function() harpoon_list:select(3) end)
vim.keymap.set('n', '<C-l>', function() harpoon_list:select(4) end)

vim.keymap.set('n', '<C-L-P>', function() harpoon_list:prev() end)
vim.keymap.set('n', '<C-L-N>', function() harpoon_list:next() end)


-- Other --

vim.api.nvim_create_user_command('GitMe', function(opts)
  if opts.args == '' then
    vim.notify(
      'Usage: :GitMe <email>',
      vim.log.levels.ERROR
    )
    return
  end

  local email = opts.args

  local function git_config(args)
    vim.fn.system(vim.list_extend({ 'git', 'config', '---local' }, args))
  end

  git_config({ 'user.name', 'Igor Domin' })
  git_config({ 'user.email', email })
  git_config({ 'core.editor', 'nvim' })

  git_config({ 'diff.algorithm', 'histogram' })
  git_config({ 'diff.colorMoved', 'zebra' })

  print('Git repo configured:')
  print('  Name : Igor Domin')
  print('  Email: ' .. email)
end, {
  nargs = 1,
  desc = 'Configure git identity + defaults for this repo',
})

vim.api.nvim_create_user_command('ZshMe', function()
  if vim.fn.executable('zsh') ~= 1 then
    vim.notify('zsh not found – skipping ~/.zshrc update', vim.log.levels.WARN)
    return
  end

  local path = vim.fn.expand('~/.zshrc')

  local block = [=[
# >>> ZSH_NVIM_SHORTCUTS >>>
# (managed by Neovim :ZshMe)

alias vim="nvim"
alias vi="nvim"

vc() {
  cd ~/.config/nvim || return
  nvim .
}

vz() {
  cd ~ || return
  nvim .zshrc
}

v() {
  if [[ $# -eq 0 ]]; then
    nvim .
  elif [[ -d "$1" ]]; then
    cd "$1" || return
    nvim .
  else
    nvim "$@"
  fi
  }

# nvim-saved-project path
__nvim_saved_project_file() {
  echo "$HOME/.local/state/nvim/nvim-saved-project"
}

# vs = save current dir as "saved project"
vs() {
  local file="$(__nvim_saved_project_file)"
  mkdir -p -- "${file:h}" || return
  print -r -- "$PWD" >| "$file"
  echo "saved: $PWD"
}

# vl = load saved project (cd + nvim .)
vl() {
  local file="$(__nvim_saved_project_file)"
  if [[ ! -f "$file" ]]; then
    echo "no saved project yet (run: vs)"
    return 1
  fi

  local dir
  dir="$(<"$file")"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    echo "saved path is invalid: $dir"
    return 1
  fi

  cd "$dir" || return
  nvim .
}

# <<< ZSH_NVIM_SHORTCUTS <<<
]=]

  local lines = {}
  if vim.fn.filereadable(path) == 1 then
    lines = vim.fn.readfile(path)
  end

  local start_marker = '# >>> ZSH_NVIM_SHORTCUTS >>>'
  local end_marker   = '# <<< ZSH_NVIM_SHORTCUTS <<<'

  local function trim_end_empty(list)
    while #list > 0 and list[#list] == '' do
      table.remove(list)
    end
  end

  local function trim_block_trailing_empty(list)
    while #list > 0 and list[#list] == '' do
      table.remove(list)
    end
  end

  local block_lines = vim.split(block, '\n', { plain = true })
  trim_block_trailing_empty(block_lines)

  local out = {}
  local inside = false
  local just_removed_block = false

  for _, line in ipairs(lines) do
    if line == start_marker then
      inside = true
      just_removed_block = true

      trim_end_empty(out)
      if #out > 0 then table.insert(out, '') end
    elseif line == end_marker then
      inside = false
    elseif not inside then
      if just_removed_block then
        if line == '' then
          goto continue
        end

        if #out > 0 and out[#out] ~= '' then
          table.insert(out, '')
        end

        just_removed_block = false
      end

      table.insert(out, line)
    end

    ::continue::
  end

  trim_end_empty(out)
  if #out > 0 then
    out[#out + 1] = ''
  end

  vim.list_extend(out, block_lines)

  vim.fn.writefile(out, path)

  vim.notify(
    'Appended Neovim shortcuts to ~/.zshrc',
    vim.log.levels.INFO
  )
end, {
  desc = 'Append Neovim shortcuts to ~/.zshrc',
})
