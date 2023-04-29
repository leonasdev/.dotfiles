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
        },
        auto_install = true,
        autotag = { -- dependency with 'nvim-ts-autotag'
          enable = true,
        },
        playground = {
          enable = true,
          disable = {},
        },
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "Select outer part of a function region" },
              ["if"] = { query = "@function.inner", desc = "Select inner part of a function region" },
              ["ac"] = { query = "@class.outer", desc = "Select outer part of a class region" },
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>xp"] = { query = "@parameter.inner", desc = "Swap parameter with the next one" },
            },
            swap_previous = {
              ["<leader>xP"] = { query = "@parameter.inner", desc = "Swap parameter with the previous one" },
            },
          },
        },
      })

      -- Must installed zig via scoop in Windows
      if _G.IS_WINDOWS then
        require("nvim-treesitter.install").compilers = { "zig" }
      else
        require("nvim-treesitter.install").compilers = { "clang", "gcc", "cc", "cl", "zig" }
      end
    end,
  },

  {
    "windwp/nvim-autopairs",
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
        },
      })
    end,
  },
}
