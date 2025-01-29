return {
  { -- Open related files
    'rgroli/other.nvim',
    keys = {
      { '<leader>oc', '<cmd>:Other<CR>', desc = '[O]pen related file in [C]urrent window' },
      { '<leader>ov', '<cmd>:OtherVSplit', desc = '[O]pen related file in [V]ertical split' },
    },
    config = function()
      -- Can't specify opts in normal lazy vim way because plugin doesn't support it
      require('other-nvim').setup {
        mappings = {
          -- Monolith BE
          { pattern = '/src/benchling/(.*).py', target = '/src/tests/unit/%1_test.py', context = 'test' },
          { pattern = '/src/tests/unit/(.*)_test.py', target = '/src/benchling/%1.py', context = 'test origin' },
          -- Monolith FE
          { pattern = '/src/client/(.*)/([a-zA-Z]*).ts', target = '/src/client/%1/__tests__/%2-test.ts', context = 'test' },
          { pattern = '/src/client/(.*)/__tests__/(.*)-test.ts', target = '/src/client/%1/%2.ts', context = 'test origin' },
          { pattern = '/src/client/(.*)/([a-zA-Z]*).tsx', target = '/src/client/%1/__tests__/%2-test.tsx', context = 'test' },
          { pattern = '/src/client/(.*)/__tests__/(.*)-test.tsx', target = '/src/client/%1/%2.tsx', context = 'test origin' },
          { pattern = '/src/client/(.*)/([a-zA-Z]*).tsx', target = '/src/client/%1/__stories__/%2.stories.tsx', context = 'story' },
          { pattern = '/src/client/(.*)/__stories__/(.*).stories.tsx', target = '/src/client/%1/%2.tsx', context = 'story origin' },
        },
        rememberBuffers = false,
      }
    end,
  },
  -- Jumping around document
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
  -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
}
