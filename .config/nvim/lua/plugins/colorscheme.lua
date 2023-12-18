return {
  {
    lazy = false,
    priority = 1000,
    dir = "~/personal/my-colorscheme/",
    config = function()
      -- vim.cmd([[colorscheme my-colorscheme]])
    end,
  },

  -- main colorscheme
  -- solarized
  {
    "ishan9299/nvim-solarized-lua",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "solarized",
        callback = function()
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
          vim.api.nvim_set_hl(0, "LineNr", { fg = "#586e75", bg = "none" })
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#b58900", bg = "none" })
          vim.api.nvim_set_hl(0, "CursorLine", { fg = "none", bg = "#002b36" })
          vim.api.nvim_set_hl(0, "Visual", { fg = "#002b36", bg = "#586e75" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#dc322f", bg = "#360909" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#b58900", bg = "#1c1500" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#268bd2", bg = "#0e3550" })
          vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#2aa198", bg = "#0a2725" })
          vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#268bd2", bg = "none" })
          vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#2aa198", bg = "none" })
          vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#586e75" })
          vim.api.nvim_set_hl(0, "LazyButton", { link = "Visual" })
          vim.api.nvim_set_hl(0, "LazyButtonActive", { link = "IncSearch" })
          vim.api.nvim_set_hl(0, "AlphaButtons", { link = "Conceal" })
          vim.api.nvim_set_hl(0, "AlphaHeader", { link = "Debug" })
          vim.api.nvim_set_hl(0, "AlphaShortcut", { italic = true, fg = "#859900" })
          vim.api.nvim_set_hl(0, "AlphaFooter", { link = "String" })
          vim.cmd("highlight GitSignsAdd guibg=none")
          vim.cmd("highlight GitSignsChange guibg=none")
          vim.cmd("highlight GitSignsDelete guibg=none")
        end,
        group = vim.api.nvim_create_augroup("FixSolarized", { clear = true }),
        desc = "Fix some highlight for solarized colorscheme",
      })

      -- temporory disable semantic tokens highlight,
      -- since ishan9299/nvim-solarized-lua not support it yet
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })

      vim.g.solarized_termtrans = 1
      vim.cmd("colorscheme solarized")
    end,
  },

  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("solarized-osaka").setup({
        transparent = false,
        -- styles = {
        --   sidebars = "transparent",
        --   floats = "transparent",
        -- },
        -- on_highlights = function(highlights, colors)
        --   highlights.Visual = {
        --     bg = colors.fg,
        --     fg = colors.bg,
        --   }
        --   highlights.AlphaButtons = {
        --     link = "Conceal",
        --   }
        --   highlights.AlphaHeader = {
        --     link = "Debug",
        --   }
        --   highlights.AlphaShortcut = {
        --     link = "@keyword",
        --   }
        -- end,
      })
      local colors = require("solarized-osaka.colors").default
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "solarized-osaka",
        callback = function()
          vim.api.nvim_set_hl(0, "Visual", { bg = colors.fg, fg = colors.bg })
          vim.api.nvim_set_hl(0, "AlphaButtons", { link = "Conceal" })
          vim.api.nvim_set_hl(0, "AlphaHeader", { link = "Debug" })
          vim.api.nvim_set_hl(0, "AlphaShortcut", { link = "@keyword" })
        end,
        group = vim.api.nvim_create_augroup("FixSolarizedOsaka", { clear = true }),
        desc = "Fix some highlight for solarized-osaka colorscheme",
      })

      -- vim.cmd([[colorscheme solarized-osaka]])
    end,
  },

  -- gruvbox-material
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "gruvbox-material",
        callback = function()
          vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
          vim.api.nvim_set_hl(0, "GruvboxYellowSign", { link = "GruvboxYellow" })
          vim.api.nvim_set_hl(0, "GruvboxPurpleSign", { link = "GruvboxPurple" })
          vim.api.nvim_set_hl(0, "GruvboxOrangeSign", { link = "GruvboxOrange" })
          vim.api.nvim_set_hl(0, "GruvboxGreenSign", { link = "GruvboxGreen" })
          vim.api.nvim_set_hl(0, "GruvboxBlueSign", { link = "GruvboxBlue" })
          vim.api.nvim_set_hl(0, "GruvboxAquaSign", { link = "GruvboxAqua" })
          vim.api.nvim_set_hl(0, "GruvboxRedSign", { link = "GruvboxRed" })
        end,
        group = vim.api.nvim_create_augroup("FixGruvboxMaterial", { clear = true }),
        desc = "Fix some highlight for gruvbox-material colorscheme",
      })
      vim.g.gruvbox_material_transparent_background = 1
    end,
  },

  -- gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("gruvbox").setup({
        transparent_mode = true,
        overrides = {
          String = { italic = false },
        },
      })
    end,
  },

  -- tokyonight
  {
    "folke/tokyonight.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("tokyonight").setup({
        transparent = true,
      })
    end,
  },

  -- nightfox
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          styles = {
            comments = "italic",
          },
        },
      })
    end,
  },

  -- kanagawa
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("kanagawa").setup({
        transparent = true,
        keywordStyle = {
          italic = false,
        },
      })
    end,
  },

  -- catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
      })
    end,
  },

  -- vscode
  {
    "Mofiqul/vscode.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("vscode").setup({
        transparent = true,
      })
    end,
  },

  -- moonbow
  {
    "arturgoms/moonbow.nvim",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("moonbow").setup({
        transparent_mode = true,
      })
    end,
  },

  -- darcula (JetBrains Intellij IDEA default theme)
  {
    "briones-gabriel/darcula-solid.nvim",
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    dependencies = {
      {
        "rktjmp/lush.nvim",
      },
    },
  },

  -- astrotheme
  {
    "AstroNvim/astrotheme",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("astrotheme").setup()
    end,
  },

  -- rose-pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("rose-pine").setup()
    end,
  },

  {
    "Shatur/neovim-ayu",
    lazy = true,
    keys = {
      { "<leader>cl", "<cmd>Telescope colorscheme<cr>", desc = "Select Colorscheme with Preview" },
    },
    config = function()
      require("ayu").setup({
        mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
        overrides = {}, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
      })
    end,
  },

  {
    "ribru17/bamboo.nvim",
    lazy = true,
    config = function()
      require("bamboo").setup()
    end,
  },
}
