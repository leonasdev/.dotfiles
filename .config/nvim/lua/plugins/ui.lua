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
      require("lualine").setup({
        options = {
          globalstatus = true,
        },
        extensions = {
          "neo-tree",
        },
      })

      vim.opt.showmode = false
    end,
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufEnter",
    config = function()
      require("colorizer").setup({
        filetypes = { "*" },
        user_default_options = {
          names = false,
          tailwind = "both",
          mode = "background",
        },
      })
    end,
  },

  -- git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = "BufEnter",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
        },
        -- signs = {
        --   add = { text = '+' },
        --   change = { text = '~' },
        --   delete = { text = '_' },
        --   topdelete = { text = '‾' },
        --   changedelete = { text = '~' },
        -- },
      })
    end,
  },

  -- Standalone UI for nvim-lsp progress
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    config = function()
      require("fidget").setup({
        window = {
          blend = 0, -- set 0 if using transparent background, otherwise set 100
        },
      })
    end,
  },

  -- Neovim plugin to improve the default vim.ui interfaces
  {
    "stevearc/dressing.nvim",
    event = "BufEnter",
    config = function()
      require("dressing").setup({
        input = {
          win_options = {
            winblend = 0,
          },
        },
      })
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<C-b>", "<cmd>Neotree toggle<cr>", mode = "n", desc = "Toggle Neotree" },
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = true,
        },
      })
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "@text.strike" })
      require("indent_blankline").setup({
        char = "",
        context_char = "│",
        show_current_context = true,
      })
    end,
  },

  {
    "luukvbaal/statuscol.nvim",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        segments = {
          { sign = { name = { "Diagnostic" } } },
          { sign = { name = { "DapBreakpoint.*" } } },
          { text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
          { sign = { name = { "GitSigns.*" } } },
        },
      })
    end,
  },
}
