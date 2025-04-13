return {
  {
    "stevearc/conform.nvim",
    dependencies = {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = require("plugins.formatting.formatters").list_ensure_installed(),
    }
  },
    ft = require("plugins.formatting.formatters").list_fts(),
    opts = {
      formatters_by_ft = require("plugins.formatting.formatters").formatters_by_ft(),
      formatters = require("plugins.formatting.formatters").get_enabled(),
      format_after_save = function(bufnr)
        if not require("plugins.formatting.autoformat").autoformat then
          return
        end

        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        if vim.tbl_contains(require("plugins.formatting.autoformat").disable_autoformat_ft, ft) then
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
