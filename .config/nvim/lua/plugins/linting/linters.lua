local default_config_dir = vim.fn.stdpath("config") .. "/lua/plugins/linting/configs/"

-- we need to wrap to_register to a function, since null-ls will loaded after
-- See https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
-- for a list of available built-in sources
return {
  pylint = {
    name = { "pylint", version = "2.4.0" }, -- for mason installer
    disabled = true,
    to_register_wrap = function()
      return require("null-ls").register(require("null-ls").builtins.diagnostics.pylint.with({
        filetypes = { "python" },
        extra_args = {
          "--rcfile",
          require("util").config_finder({ ".pylintrc", "pylintrc" }, default_config_dir),
        },
      }))
    end,
  },
  staticcheck = {
    name = { "staticcheck" }, -- for mason installer
    to_register_wrap = function()
      return require("null-ls").register(require("null-ls").builtins.diagnostics.staticcheck.with({
        filetypes = { "go" },
      }))
    end,
  },
  hadolint = {
    name = { "hadolint" }, -- for mason installer
    to_register_wrap = function()
      return require("null-ls").register(require("null-ls").builtins.diagnostics.hadolint.with({
        filetypes = { "dockerfile" },
      }))
    end,
  },
}
