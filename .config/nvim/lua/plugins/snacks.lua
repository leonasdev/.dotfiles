return {
  -- TODO: move to lsp
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      { "gd", function() Snacks.picker.lsp_definitions() end, mode = "n" },
      { "gr", function() Snacks.picker.lsp_references() end, mode = "n" },
      { "gi", function() Snacks.picker.lsp_implementations() end, mode = "n" },
    },
    ---@type snacks.Config
    opts = {},
  },
}
