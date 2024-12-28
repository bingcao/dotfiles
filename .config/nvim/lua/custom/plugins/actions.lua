return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup {
        mappings = {
          add = 'ysa', -- Add surrounding in Normal and Visual modes
          delete = 'ysd', -- Delete surrounding
          find = 'ysf', -- Find surrounding (to the right)
          find_left = 'ysF', -- Find surrounding (to the left)
          highlight = 'ysh', -- Highlight surrounding
          replace = 'ysr', -- Replace surrounding
          update_n_lines = 'ysn', -- Update `n_lines`
        },
      }

      -- File explorer
      require('mini.files').setup {
        content = {
          sort = function(entries)
            -- technically can filter entries here too, and checking gitignore for _every entry individually_
            -- like I would have to in `content.filter` above is too slow. Here we can give it _all_ the entries
            -- at once, which is much more performant.
            local all_paths = table.concat(
              vim.tbl_map(function(entry)
                return entry.path
              end, entries),
              '\n'
            )
            local output_lines = {}
            local job_id = vim.fn.jobstart({ 'git', 'check-ignore', '--stdin' }, {
              stdout_buffered = true,
              on_stdout = function(_, data)
                output_lines = data
              end,
            })

            -- command failed to run
            if job_id < 1 then
              return entries
            end

            -- send paths via STDIN
            vim.fn.chansend(job_id, all_paths)
            vim.fn.chanclose(job_id, 'stdin')
            vim.fn.jobwait { job_id }
            return require('mini.files').default_sort(vim.tbl_filter(function(entry)
              return not vim.tbl_contains(output_lines, entry.path)
            end, entries))
          end,
        },
      }
      vim.keymap.set('n', '<leader>fa', '<cmd>lua MiniFiles.open()<CR>', { desc = 'Navigate [F]iles [A]ll' })
      vim.keymap.set('n', '<leader>fc', '<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', { desc = 'Navigate [F]iles from [C]urrent file' })
    end,
  },
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
