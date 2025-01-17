return {
  {
    'freddiehaddad/feline.nvim',
    config = function()
      local colors = require('tokyonight.colors').setup { style = 'moon' }
      local c = {
        vim_mode = {
          provider = {
            name = 'vi_mode',
            opts = {
              show_mode_name = true,
            },
          },
          icon = '',
          hl = function()
            return {
              fg = require('feline.providers.vi_mode').get_mode_color(),
              bg = 'bg_dark',
              style = 'bold',
              name = 'NeovimModeHLColor',
            }
          end,
          left_sep = 'block',
          right_sep = 'block',
        },
        gitBranch = {
          provider = 'git_branch',
          hl = {
            fg = 'yellow',
            bg = 'bg_dark',
            style = 'bold',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        gitDiffAdded = {
          provider = 'git_diff_added',
          hl = {
            fg = colors.git.add,
            bg = 'bg_dark',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        gitDiffRemoved = {
          provider = 'git_diff_removed',
          hl = {
            fg = colors.git.delete,
            bg = 'bg_dark',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        gitDiffChanged = {
          provider = 'git_diff_changed',
          hl = {
            fg = colors.git.change,
            bg = 'bg_dark',
          },
          left_sep = 'block',
          right_sep = 'right_filled',
        },
        separator = {
          provider = '',
        },
        fileinfo = {
          provider = {
            name = 'file_info',
            opts = {
              type = 'full-path',
            },
          },
          hl = {
            style = 'bold',
          },
          left_sep = ' ',
          right_sep = ' ',
        },
        diagnostic_errors = {
          provider = 'diagnostic_errors',
          hl = {
            fg = 'red',
          },
        },
        diagnostic_warnings = {
          provider = 'diagnostic_warnings',
          hl = {
            fg = 'yellow',
          },
        },
        diagnostic_hints = {
          provider = 'diagnostic_hints',
          hl = {
            fg = 'aqua',
          },
        },
        diagnostic_info = {
          provider = 'diagnostic_info',
        },
        lsp_client_names = {
          provider = 'lsp_client_names',
          hl = {
            fg = 'purple',
            bg = 'bg_dark',
            style = 'bold',
          },
          left_sep = 'left_filled',
          right_sep = 'block',
        },
        file_type = {
          provider = {
            name = 'file_type',
            opts = {
              filetype_icon = true,
              case = 'titlecase',
            },
          },
          hl = {
            fg = 'red',
            bg = 'bg_dark',
            style = 'bold',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        file_encoding = {
          provider = 'file_encoding',
          hl = {
            fg = 'orange',
            bg = 'bg_dark',
            style = 'italic',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        position = {
          provider = 'position',
          hl = {
            fg = 'green',
            bg = 'bg_dark',
            style = 'bold',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        line_percentage = {
          provider = 'line_percentage',
          hl = {
            fg = 'aqua',
            bg = 'bg_dark',
            style = 'bold',
          },
          left_sep = 'block',
          right_sep = 'block',
        },
        scroll_bar = {
          provider = 'scroll_bar',
          hl = {
            fg = 'yellow',
            style = 'bold',
          },
        },
      }

      local left = {
        c.vim_mode,
        c.gitBranch,
        c.gitDiffAdded,
        c.gitDiffRemoved,
        c.gitDiffChanged,
        c.separator,
      }

      local middle = {
        c.fileinfo,
        c.diagnostic_errors,
        c.diagnostic_warnings,
        c.diagnostic_info,
        c.diagnostic_hints,
      }

      local right = {
        c.lsp_client_names,
        c.file_type,
        c.file_encoding,
        c.position,
        c.line_percentage,
        c.scroll_bar,
      }

      local components = {
        active = {
          left,
          middle,
          right,
        },
        inactive = { {}, { c.fileinfo }, {} },
      }
      require('feline').setup {
        components = components,
        theme = colors,
        disable = {
          filetypes = {
            '^neo%-tree$',
            '^NvimTree$',
            '^packer$',
            '^startify$',
            '^fugitive$',
            '^fugitiveblame$',
            '^qf$',
            '^help$',
          },
          buftypes = {
            '^terminal$',
          },
          bufnames = {},
        },
      }
    end,
  },
}
