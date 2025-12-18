return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.2.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim', build = 'make'
    },
    {
      "nvim-tree/nvim-web-devicons", opts = {}
    },
    {
      'nvim-telescope/telescope-ui-select.nvim', opts = {}
    },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    })

    telescope.load_extension("fzf")
  end,
}
