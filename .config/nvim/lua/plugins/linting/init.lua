local linters = require("plugins.linting.linters")
local sources = {} -- a list of to_register_wrap
for linter, setting in pairs(linters) do
  if not setting.disabled then
    sources[linter] = setting.to_register_wrap
  end
end

return {
  {
    "nvimtools/none-ls.nvim",
    opts = sources, -- passed to the parent spec's config()
  },

  {
    "mfussenegger/nvim-lint",
    config = function()
      require("lint").linters_by_ft = {
        python = { "pylint" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "TextChanged", "BufEnter" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
