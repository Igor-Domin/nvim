return {
  'theprimeagen/harpoon',
  branch = 'harpoon2',
  commit = '87b1a35',
  dependencies = {
    -- { 'nvim-lua/plenary.nvim',         commit = 'b9fd522' },
    -- { 'nvim-telescope/telescope.nvim', tag = 'v0.2.0' },
  },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup({})

    local telescope_config = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(paths, item.value)
      end

      require('telescope.pickers').new({}, {
        prompt_title = 'Harpoon',
        finder = require('telescope.finders').new_table({
          results = paths,
        }),
        previewer = telescope_config.file_previewer({}),
        sorter = telescope_config.generic_sorter({}),
      }):find()
    end

    vim.keymap.set('n', '<leader>Q', function() toggle_telescope(harpoon:list()) end, { desc = 'Open harpoon window' })
  end,
}
