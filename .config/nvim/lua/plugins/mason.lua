return {
  -- managing tool
  {
    "williamboman/mason.nvim",
    dependencies = {
      -- bridges mason with the lspconfig
      { "williamboman/mason-lspconfig.nvim" },

      -- Install and upgrade third party tools automatically
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        config = function()
          local langueage_servers = require("plugins.lsp.langueage_servers")
          local formatters = require("plugins.formatting.formatters")
          local adapters = require("plugins.dap.adapters")
          local linters = require("plugins.linting.linters")
          local tool_names = {}
          for _, server in pairs(langueage_servers) do
            table.insert(tool_names, server.name)
          end
          for _, formatter in pairs(formatters) do
            table.insert(tool_names, formatter.name)
          end
          for _, adapter in pairs(adapters) do
            table.insert(tool_names, adapter.name)
          end
          for _, linter in pairs(linters) do
            table.insert(tool_names, linter.name)
          end
          require("mason-tool-installer").setup({
            ensure_installed = tool_names,
          })
        end,
      },
    },
    config = function()
      require("mason").setup({
        providers = {
          "mason.providers.registry-api", -- default
          "mason.providers.client",
        },
        ui = {
          height = 0.85,
          border = "rounded",
        },
      })

      require("mason-lspconfig").setup()
    end,
  },
}
