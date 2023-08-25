local default_config_dir = vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/"

-- we need to wrap to_register to a function, since null-ls will loaded after
-- See https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
-- for a list of available built-in sources
return {
  rustfmt = {
    name = "rustfmt", -- for mason installer
    disabled = false,
    to_register_wrap = function()
      return require("null-ls").builtins.formatting.rustfmt.with({
        filetypes = { "rust" },
      })
    end,
  },
  prettier = {
    name = "prettier",
    disabled = false,
    to_register_wrap = function()
      return require("null-ls").builtins.formatting.prettier.with({
        filetypes = { "html", "css", "scss" },
        extra_args = { "--print-width", "120" },
      })
    end,
  },
  dprint = {
    name = "dprint",
    disabled = false,
    to_register_wrap = function()
      return require("null-ls").builtins.formatting.dprint.with({
        filetypes = {
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "json",
          "javascript",
        },
        -- check if project have dprint configuration
        extra_args = {
          "--config",
          require("util").config_finder({ "dprint.json", ".dprint.json" }, default_config_dir),
        },
      })
    end,
  },
  stylua = {
    name = "stylua",
    disabled = false,
    to_register_wrap = function()
      return require("null-ls").builtins.formatting.stylua.with({
        filetypes = { "lua" },
        extra_args = {
          "--config-path",
          require("util").config_finder({ "stylua.toml", ".stylua.toml" }, default_config_dir),
        },
      })
    end,
  },
}
