-- Normal mode --
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { silent = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { silent = true })

vim.keymap.set("n", "<leader>fe", vim.cmd.Ex)

vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<leader>y", '"+yy', { desc = "Yank line to clipboard" })
vim.keymap.set('n', "<leader>Y", ':%y+<CR>', { desc = "Yank whole file to clipboard" })

vim.keymap.set('n', '<leader>u', function() vim.cmd.UndotreeToggle() end)

vim.keymap.set('n', "<leader>gs", vim.cmd.Git)


-- Insert mode --
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { silent = true })
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi", { silent = true })


-- Visual mode --
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { silent = true })

vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank selection to clipboard" })
vim.keymap.set("v", "<leader>rs", [[y:%s/\V<C-r>"/<C-r>"/gI<Left><Left><Left>]])


-- Telescope --
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>fw', function()
  builtin.grep_string({
    search = vim.fn.expand('<cword>'),
  })
end)

vim.keymap.set('n', '<leader>fa', builtin.live_grep, {})

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})

vim.keymap.set("n", "<leader>fg", function()
  local git_dir = vim.fn.finddir(".git", ".;")
  if git_dir == "" then
    print("Not a git repository. Using find_files instead.")
    require("telescope.builtin").find_files()
    return
  end
  require("telescope.builtin").git_files()
end)


-- Harpoon --
local harpoon = require('harpoon')
local list = harpoon:list()
harpoon:setup()
vim.keymap.set('n', "<leader>q", function() harpoon.ui:toggle_quick_menu(list) end)
vim.keymap.set('n', "<leader>a", function() list:add() end)
vim.keymap.set('n', '<leader>A', function()
  list:remove()
  list:prepend()
end)

vim.keymap.set('n', "<C-h>", function() list:select(1) end)
vim.keymap.set('n', "<C-j>", function() list:select(2) end)
vim.keymap.set('n', "<C-k>", function() list:select(3) end)
vim.keymap.set('n', "<C-l>", function() list:select(4) end)

vim.keymap.set("n", "<C-L-P>", function() list:prev() end)
vim.keymap.set("n", "<C-L-N>", function() list:next() end)


-- Run --
local function display_result(output, time_output)
  local user = time_output:match("([%d.]+)s user")
  local sys  = time_output:match("([%d.]+)s system")
  local real = time_output:match("([%d.]+) total")

  vim.api.nvim_echo({
    { "Output:\n\n\n",      "SpellRare" },
    { output .. "\n\n\n",   "Normal" },
    { "Time: ",             "Type" },
    { "real ",              "Constant" },
    { (real or "?") .. "s", "Type" },
    { " | ",                "PreProc" },
    { "user ",              "Constant" },
    { (user or "?") .. "s", "Type" },
    { " | ",                "PreProc" },
    { "sys ",               "Constant" },
    { (sys or "?") .. "s",  "Type" },
  }, true, {})
end

local function run(shell_cmd, cwd, display_output)
  vim.system(
    { "/bin/zsh", "-c", shell_cmd },
    { text = true, cwd = cwd },
    function(result)
      vim.schedule(function()
        local output      = vim.trim(result.stdout or "")
        local time_output = vim.trim(result.stderr or "")

        if result.code ~= 0 then
          print("Failed:\n\n" .. time_output)
          return
        end

        if display_output then
          time_output = time_output:match("[^\n]+%s+total$") or ""
        end

        display_result(output, time_output)
      end)
    end
  )
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "haskell",
  callback = function()
    vim.keymap.set("n", "<leader>cr", function()
      vim.cmd("write")
      local file = vim.fn.expand("%:t")
      local dir  = vim.fn.expand("%:p:h")
      run(string.format("time runghc %s", file), dir)
    end, { buffer = true, desc = "Haskell: run (interpreted)" })

    vim.keymap.set("n", "<leader>cb", function()
      vim.cmd("write")
      local file = vim.fn.expand("%:t")
      local bin  = vim.fn.expand("%:t:r")
      local dir  = vim.fn.expand("%:p:h")
      run(
        string.format(
          "time (ghc %s -O2 -o %s > /dev/null && rm -f %s.o %s.hi && ./%s)",
          file, bin, bin, bin, bin
        ),
        dir
      )
    end, { buffer = true, desc = "Haskell: build + run (compiled)" })

    vim.keymap.set("n", "<leader>cR", function()
      local bin = vim.fn.expand("%:t:r")
      local dir = vim.fn.expand("%:p:h")
      run(string.format("time ./%s", bin), dir)
    end, { buffer = true, desc = "Haskell: run (compiled)" })
  end,
})


-- Other --

vim.api.nvim_create_user_command("GitMe", function(opts)
  if opts.args == "" then
    vim.notify(
      "Usage: :GitMe <email>",
      vim.log.levels.ERROR
    )
    return
  end

  local email = opts.args

  local function git(args)
    vim.fn.system(vim.list_extend({ "git", "config", "--local" }, args))
  end

  git({ "user.name", "Igor Domin" })
  git({ "user.email", email })
  git({ "core.editor", "nvim" })

  git({ "diff.algorithm", "histogram" })
  git({ "diff.colorMoved", "zebra" })
  git({ "rebase.autoStash", "true" })
  git({ "pull.rebase", "true" })

  print("Git repo configured:")
  print("  Name : Igor Domin")
  print("  Email: " .. email)
end, {
  nargs = 1,
  desc = "Configure git identity + defaults for this repo",
})
