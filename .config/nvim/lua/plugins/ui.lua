return {
  -- nerd font supported icons
  {
    "kyazdani42/nvim-web-devicons",
    lazy = true,
  },

  -- status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup {
        theme = "solarized_dark",
        globalstatus = true,
      }
    end
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufEnter",
    config = function()
      require("colorizer").setup {
        user_default_options = {
          filetypes = { "*" },
          names = false,
          tailwind = true,
        }
      }
    end
  },

  -- git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = "BufEnter",
    config = function()
      require("gitsigns").setup {
        -- signs = {
        --   add = { text = '+' },
        --   change = { text = '~' },
        --   delete = { text = '_' },
        --   topdelete = { text = '‾' },
        --   changedelete = { text = '~' },
        -- },
      }
    end
  },

  -- Standalone UI for nvim-lsp progress
  {
    "j-hui/fidget.nvim",
    event = "BufEnter",
    config = function()
      require("fidget").setup {
        window = {
          blend = 0 -- set 0 if using transparent background, otherwise set 100
        },
      }
    end
  },
}
