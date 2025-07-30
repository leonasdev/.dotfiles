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
      vim.g.diagnostic_enabled = true
      local toggle_diag = Snacks.toggle.diagnostics()
      Snacks.toggle({
        name = "Diagnostics",
        get = function() return toggle_diag:get() end,
        set = function(state)
          toggle_diag:set(state)
          if not state then
            require("util").close_diagnostic_float()
          end
          vim.g.diagnostic_enabled = state
        end,
      }):map("<leader>td")

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
              if not vim.g.diagnostic_enabled then
                return
              end
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

      local servers = require("plugins.lsp.langueage_servers").get_enabled()
      local ensure_installed = {}
      for server, server_opts in pairs(servers) do
        vim.lsp.config(server, server_opts.config or {})
        vim.lsp.enable(server)
        table.insert(ensure_installed, server)
      end
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        automatic_installation = false,
        automatic_enable = false,
      })

      -- Temporarily work around for this pyright issue:
      -- https://github.com/neovim/neovim/issues/34731
      local util = require("vim.lsp.util")
      local original_apply_text_edits = util.apply_text_edits
      util.apply_text_edits = function(text_edits, bufnr, position_encoding, change_annotations)
        local pyright = vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })[1]

        for _, edit in ipairs(text_edits or {}) do
          if pyright and edit.annotationId then
            edit.annotationId = nil
          end
        end

        return original_apply_text_edits(text_edits, bufnr, position_encoding, change_annotations)
      end
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
