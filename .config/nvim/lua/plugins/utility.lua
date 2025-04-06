return {
  { -- lua library for neovim
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "folke/snacks.nvim",
    opts = {
      bigfile = { enabled = true },
    },
  },
}
