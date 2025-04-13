return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = function(_, opts)
      local icons = require("util.icons")
      local ret = {
        ensure_installed = opts.ensure_installed or {},
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
      }
      return ret
    end,
    config = function(_, opts)
      require("mason").setup(opts)
      local mason_registry = require("mason-registry")
      mason_registry:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mason_registry.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mason_registry.get_package(tool)
          if not p:is_installed() then
            require("lazy.util").info("[mason] installing " .. tool)
            p:install()
          end
        end
      end)
    end,
  },
}
