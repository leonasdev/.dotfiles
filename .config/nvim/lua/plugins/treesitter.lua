return {
  -- Syntax highlightings
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/playground",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup({
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
          disable = { "python" },
        },
        ensure_installed = {
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "bash",
          "regex",
          "c",
          "cpp",
          "go",
          "gomod",
          "java",
          "javascript",
          "typescript",
          "tsx",
          "json",
          "toml",
          "html",
          "css",
          "scss",
          "lua",
          "rust",
          "kdl",
        },
        auto_install = true,
        autotag = { -- dependency with 'nvim-ts-autotag'
          enable = true,
        },
        playground = {
          enable = true,
          disable = {},
        },
        -- textobjects = {
        --   select = {
        --     enable = true,
        --     -- Automatically jump forward to textobj, similar to targets.vim
        --     lookahead = true,
        --     keymaps = {
        --       ["af"] = { query = "@function.outer", desc = "Select outer part of a function region" },
        --       ["if"] = { query = "@function.inner", desc = "Select inner part of a function region" },
        --       ["ac"] = { query = "@class.outer", desc = "Select outer part of a class region" },
        --       ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
        --     },
        --   },
        --   swap = {
        --     enable = true,
        --     swap_next = {
        --       ["<leader>xp"] = { query = "@parameter.inner", desc = "Swap parameter with the next one" },
        --     },
        --     swap_previous = {
        --       ["<leader>xP"] = { query = "@parameter.inner", desc = "Swap parameter with the previous one" },
        --     },
        --   },
        -- },
      })

      -- Must installed zig via scoop in Windows
      -- if _G.IS_WINDOWS then
      --   require("nvim-treesitter.install").compilers = { "zig" }
      -- else
      --   require("nvim-treesitter.install").compilers = { "gcc", "clang", "gcc", "cc", "cl", "zig" }
      -- end
    end,
  },

  {
    "windwp/nvim-autopairs",
    enabled = false,
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  {
    "kylechui/nvim-surround",
    event = "BufEnter",
    config = function()
      require("nvim-surround").setup({
        keymaps = {
          normal = "s",
          normal_cur = "ss",
          visual = "s",
        },
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufEnter",
    config = function()
      require("treesitter-context").setup({
        enable = false, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20, -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
      vim.api.nvim_set_keymap("n", "<leader>tc", ":TSContextToggle<CR>", { noremap = true, silent = true })
    end,
  },

  -- vim syntax for helm templates (yaml + gotmpl + sprig + custom)
  { "towolf/vim-helm" },
}
