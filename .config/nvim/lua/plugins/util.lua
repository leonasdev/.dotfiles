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
      vim.api.nvim_set_hl(0, 'ZenBg', { ctermbg=0 })
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
}