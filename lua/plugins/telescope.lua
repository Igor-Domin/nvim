return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.2.0',
  -- commit = '3d757e5',
  dependencies = {
    -- { 'nvim-lua/plenary.nvim',         commit = 'b9fd522' },
    -- {
    -- 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', commit = '6fea601'
    -- },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        sorting_strategy = 'ascending',
        layout_config = {
          vertical = { width = 0.5 }
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          -- },
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    })

    telescope.load_extension("fzf")
  end,
}
