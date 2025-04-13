return {
  -- configuration for nvim lsp
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
    },
    opts = function()
      local icons = require("util.icons")
      -- options for vim.diagnostic.config()
      ---@type vim.diagnostic.Opts
      local ret = {
        diagnostics = {
          update_in_insert = false,
          severity_sort = true,
          virtual_text = {
            prefix = icons.diagnostics.virtual_text.prefix,
            severity_sort = true,
          },
          float = {
            border = "rounded",
            source = true, -- Always show the source of diagnostic
            prefix = "- ",
          },
          signs = {
            linehl = {
              [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLn",
              [vim.diagnostic.severity.WARN] = "DiagnosticWarnLn",
              [vim.diagnostic.severity.INFO] = "DiagnosticInfoLn",
              [vim.diagnostic.severity.HINT] = "DiagnosticHintLn",
            },
            text = {
              [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
              [vim.diagnostic.severity.WARN] = icons.diagnostics.warn,
              [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
              [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
            },
          },
        },
      }

      return ret
    end,
    config = function(_, opts)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          require("plugins.lsp.keymaps").on_attach(bufnr)
          -- auto show diagnostic on CursorMoved and WinResized
          vim.api.nvim_create_autocmd({ "CursorMoved", "WinResized" }, {
            buffer = bufnr,
            callback = function()
              require("util").close_diagnostic_float()
              local _, win = vim.diagnostic.open_float({
                nil,
                close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "InsertCharPre" },
              })
              vim.g.diagnostic_float_win = win
            end,
          })
        end,
      })

      vim.diagnostic.config(opts.diagnostics)

      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local has_blink, blink = pcall(require, "blink.cmp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        has_blink and blink.get_lsp_capabilities() or {}
      )

      local servers = require("plugins.lsp.langueage_servers").get_enabled()
      local function setup_server(server)
        if not servers[server] or not servers[server].enabled then
          return
        end
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})
        require("lspconfig")[server].setup(server_opts)
      end

      local ensure_installed = {}
      for server, _ in pairs(require("plugins.lsp.langueage_servers").get_enabled()) do
        table.insert(ensure_installed, server)
      end
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        handlers = { setup_server },
        automatic_installation = false,
      })
    end,
  },

  -- for developing neovim
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
  },
}
