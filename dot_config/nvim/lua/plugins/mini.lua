return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'nvim-treesitter/nvim-treesitter-textobjects' },
    config = function()
      local spec_treesitter = require('mini.ai').gen_spec.treesitter
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup {
        custom_textobjects = {
          F = spec_treesitter { a = '@function.outer', i = '@function.inner' },
        },
        n_lines = 500,
      }

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

      require('mini.pairs').setup {}

      -- File explorer
      require('mini.files').setup {
        content = {
          sort = function(entries)
            -- technically can filter entries here too, and checking gitignore for _every entry individually_
            -- like I would have to in `content.filter` above is too slow. Here we can give it _all_ the entries
            -- at once, which is much more performant.
            local all_paths = table.concat(vim.tbl_map(function(entry) return entry.path end, entries), '\n')
            local output_lines = {}
            local job_id = vim.fn.jobstart({ 'git', 'check-ignore', '--stdin' }, {
              stdout_buffered = true,
              on_stdout = function(_, data) output_lines = data end,
            })

            -- command failed to run
            if job_id < 1 then return entries end

            -- send paths via STDIN
            vim.fn.chansend(job_id, all_paths)
            vim.fn.chanclose(job_id, 'stdin')
            vim.fn.jobwait { job_id }
            return require('mini.files').default_sort(vim.tbl_filter(function(entry) return not vim.tbl_contains(output_lines, entry.path) end, entries))
          end,
        },
      }
      vim.keymap.set('n', '<leader>fa', '<cmd>lua MiniFiles.open()<CR>', { desc = 'Navigate [F]iles [A]ll' })
      vim.keymap.set('n', '<leader>fc', '<cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', { desc = 'Navigate [F]iles from [C]urrent file' })
    end,
  },
}
