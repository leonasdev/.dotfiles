return {
  -- lua library for neovim
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- Distraction-free coding for Neovim
  {
    "folke/zen-mode.nvim",
    cmd = "Zen",
    config = function()
      vim.api.nvim_set_hl(0, 'ZenBg', { ctermbg = 0 })
    end
  },

  -- measure startuptime
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },

  -- commenting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end
  },

  -- folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      vim.o.foldcolumn = '0' -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

      require('ufo').setup({
        provider_selector = function(bufnr, filetype, buftype)
          return { 'treesitter', 'indent' }
        end
      })
    end
  },

  -- auto detect indent
  {
    "nmac427/guess-indent.nvim",
    config = function()
      require("guess-indent").setup()
    end
  },

  -- git wrapper
  {
    "tpope/vim-fugitive",
    config = function()
    end
  }
}
