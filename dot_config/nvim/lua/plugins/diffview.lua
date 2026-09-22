return {
  'sindrets/diffview.nvim',
  keys = {
    { '<leader>do', '<cmd>DiffviewOpen HEAD<CR>', desc = '[D]iff [O]pen' },
    { '<leader>dc', '<cmd>DiffviewClose<CR>', desc = '[D]iff [C]lose' },
    { '<leader>dh', '<cmd>DiffviewFileHistory %<CR>', desc = '[D]iff file [H]istory' },
    { '<leader>dH', '<cmd>DiffviewFileHistory<CR>', desc = '[D]iff repo [H]istory' },
    {
      '<leader>db',
      function()
        vim.ui.input({ prompt = 'Base branch: ', default = 'dev' }, function(branch)
          if branch then
            vim.cmd('DiffviewOpen ' .. branch .. '...HEAD')
          end
        end)
      end,
      desc = '[D]iff [B]ranch comparison',
    },
    { '<leader>dl', ":'<,'>DiffviewFileHistory<CR>", mode = 'v', desc = '[D]iff [L]ine history' },
  },
}
