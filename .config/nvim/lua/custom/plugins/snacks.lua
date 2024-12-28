return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = {
      sections = {
        { section = 'header' },
        { section = 'keys', gap = 1, padding = 1 },
        { section = 'startup' },
        {
          section = 'terminal',
          cmd = 'sudo pokemon-colorscripts -r --no-title; sleep .1',
          random = 10,
          pane = 2,
          indent = 4,
          height = 30,
        },
      },
    },
    gitbrowse = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    notify = { enabled = true },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scratch = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    { '<leader>gb', function() Snacks.gitbrowse() end, desc = 'Git Browse' },
    { '<leader>gg', function() Snacks.gitbrowse() end, desc = 'Open Lazygit' },
    { '<leader>gl', function() Snacks.gitbrowse() end, desc = 'Lazygit log file' },
    { '<leader>nd', function() Snacks.notifier.hide() end, desc = 'Dismiss All Notifications' },
    { '<leader>nh', function() Snacks.notifier.show_history() end, desc = 'Notification History' },
    { '<leader>S.', function() Snacks.scratch() end, desc = 'Toggle scratch buffer' },
    { '<leader>Ss', function() Snacks.scratch.select() end, desc = 'Select Scratch Buffer' },
    { '<C-t>', function() Snacks.terminal() end, desc = 'Toggle Terminal' },
  },
}
