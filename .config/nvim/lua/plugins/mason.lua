return {
  -- managing tool
  {
    "williamboman/mason.nvim",
    -- It's important that you set up the plugins in the following order:
    -- 1. mason.nvim
    -- 2. mason-lspconfig.nvim
    -- 3. Setup servers via lspconfig
    priority = 100,
    dependencies = {
      -- bridges mason with the lspconfig
      {
        priority = 80,
        "williamboman/mason-lspconfig.nvim",
        config = function()
          require("mason-lspconfig").setup({})
        end,
      },

      -- Install and upgrade third party tools automatically
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        priority = 90,
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
    end,
  },
}
