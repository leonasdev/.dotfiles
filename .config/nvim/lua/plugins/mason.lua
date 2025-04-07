return {
  -- managing tool
  {
    "williamboman/mason.nvim",
    lazy = true,
    dependencies = {
      -- bridges mason with the lspconfig
      { "williamboman/mason-lspconfig.nvim" },

      -- Install and upgrade third party tools automatically
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        config = function()
          local langueage_servers = require("plugins.lsp.langueage_servers")
          local formatters = {}
          for _, formatter in pairs(require("conform").list_all_formatters()) do
            table.insert(formatters, formatter.command)
          end
          local adapters = require("plugins.dap.adapters")
          local tool_names = {}
          for server, _ in pairs(langueage_servers) do
            local tool_name = require("mason-lspconfig.mappings.server").lspconfig_to_package[server]
            table.insert(tool_names, tool_name)
          end
          for _, formatter in pairs(formatters) do
            table.insert(tool_names, formatter)
          end
          for _, adapter in pairs(adapters) do
            table.insert(tool_names, adapter.name)
          end
          require("mason-tool-installer").setup({
            ensure_installed = tool_names,
          })
        end,
      },
    },
    config = function()
      local icons = require("util.icons")
      require("mason").setup({
        providers = {
          "mason.providers.registry-api", -- default
          "mason.providers.client",
        },
        ui = {
          height = 0.85,
          border = "rounded",
          icons = {
            package_installed = icons.status.check,
            package_pending = icons.status.uncheck,
            package_uninstalled = icons.status.uncheck,
          },
        },
      })

      require("mason-lspconfig").setup()
    end,
  },
}
