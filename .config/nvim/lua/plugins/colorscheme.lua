return {
  -- main colorscheme
  -- solarized
  {
    "ishan9299/nvim-solarized-lua",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.g.solarized_termtrans = 1

      vim.cmd("colorscheme solarized")

      vim.api.nvim_set_hl(0, 'NormalFloat', { bg='none' })
      vim.api.nvim_set_hl(0, 'LineNr', { fg='#586e75', bg='none' })
      vim.api.nvim_set_hl(0, 'CursorLineNr', { fg='#b58900', bg='none' })
      vim.api.nvim_set_hl(0, 'CursorLine', { fg='none', bg='#002b36' })
      vim.api.nvim_set_hl(0, 'Visual', { fg='#002b36', bg='#586e75'})
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg='#dc322f', bg='#360909'})
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', { fg='#b58900', bg='#1c1500'})
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', { fg='#268bd2', bg='#0e3550'})
      vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextHint', { fg='#2aa198', bg='#0a2725'})
      vim.api.nvim_set_hl(0, 'PmenuSel', { bg='#586e75'})
      vim.cmd('highlight GitSignsAdd guibg=none')
      vim.cmd('highlight GitSignsChange guibg=none')
      vim.cmd('highlight GitSignsDelete guibg=none')
    end
  },

  -- gruvbox-material
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    config = function()
      vim.g.gruvbox_material_transparent_background = 1
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg='none' })
      vim.api.nvim_set_hl(0, 'GruvboxYellowSign', { link = 'GruvboxYellow' })
      vim.api.nvim_set_hl(0, 'GruvboxPurpleSign', { link = 'GruvboxPurple' })
      vim.api.nvim_set_hl(0, 'GruvboxOrangeSign', { link = 'GruvboxOrange' })
      vim.api.nvim_set_hl(0, 'GruvboxGreenSign', { link = 'GruvboxGreen' })
      vim.api.nvim_set_hl(0, 'GruvboxBlueSign', { link = 'GruvboxBlue' })
      vim.api.nvim_set_hl(0, 'GruvboxAquaSign', { link = 'GruvboxAqua' })
      vim.api.nvim_set_hl(0, 'GruvboxRedSign', { link = 'GruvboxRed' })
    end
  },

  -- gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    config = function()
      require("gruvbox").setup {
        transparent_mode = true,
        overrides = {
          String = { italic = false},
        },
      }
    end
  },

  -- tokyonight
  {
    "folke/tokyonight.nvim",
    lazy = true,
    config = function()
      require("tokyonight").setup {
        transparent = true,
      }
    end
  },

  -- nightfox
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    config = function()
      require("nightfox").setup {
        options = {
          transparent = true,
          styles = {
            comments = "italic",
          },
        },
      }
    end
  },

  -- kanagawa
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    config = function()
      require("kanagawa").setup {
        transparent_background = true
      }
    end
  },

  -- catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    config = function()
      require("catppuccin").setup {
        transparent = true,
        specialReturn = false,
      }
    end
  },

  -- vscode
  {
    "Mofiqul/vscode.nvim",
    lazy = true,
  },

}
