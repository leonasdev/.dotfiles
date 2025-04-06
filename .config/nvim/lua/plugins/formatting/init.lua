local default_config_dir = vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/"
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        go = { "gofumpt" },
        json = { "fixjson" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
      },
      formatters = {
        stylua = {
          prepend_args = function()
            return {
              "--config-path",
              require("util").config_finder({ "stylua.toml", ".stylua.toml" }, default_config_dir),
            }
          end,
        },
        ruff_format = {
          prepend_args = function()
            return {
              "--config",
              require("util").config_finder({ "ruff.toml", "pyproject.toml" }, default_config_dir),
            }
          end,
        },
        prettier = {
          prepend_args = { "--print-width", "120" },
        },
      },
      format_after_save = function(bufnr)
        if not require("plugins.formatting.autoformat").autoformat then
          return
        end

        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        if vim.tbl_contains(require("plugins.formatting.autoformat").disable_autoformat, ft) then
          return
        end

        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
    config = function(_, opts)
      vim.api.nvim_create_user_command(
        "FormatToggle",
        function() require("plugins.formatting.autoformat").toggle() end,
        { desc = "Toggle Format on Save" }
      )

      vim.keymap.set(
        "n",
        "<leader>tf",
        function() require("plugins.formatting.autoformat").toggle() end,
        { expr = true, desc = "Toggle Format on Save" }
      )

      require("conform").setup(opts)
    end,
  },
}
