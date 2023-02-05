local function lsp_related_ui_adjust()
  require("lspconfig.ui.windows").default_options.border = "rounded"
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  vim.diagnostic.config({
    virtual_text = {
      prefix = '●',
      severity_sort = true,
    },
    float = {
      border = "rounded",
      source = "always", -- Or "if_many"
      prefix = " - ",
    },
    severity_sort = true,
  })
end

local format_on_save = false

local servers = {
  html = true,
  pyright = true,
  clangd = not _G.IS_WINDOWS, -- DO NOT DEVELOP C++ IN WINDOWS!
  gopls = true,
  tsserver = true,
  eslint = {
    filetypes = { "javascript", "javascriptreact", "javascript.jsx"}
  },
  cssls = true,
  volar = true,
  tailwindcss = true,
  sumneko_lua = {
    settings = {
      Lua = {
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { 'vim' }
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          -- library = vim.api.nvim_get_runtime_file("", true),
          library = {
            vim.fn.stdpath("config"),
          },
          checkThirdParty = false
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false
        }
      }
    }
  }
}

local function lspconfig_setup()
  local on_attach = function(_, bufnr)
    if format_on_save then
      -- auto formatting when save file
      local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })
      vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup_format,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end

    local opts = { buffer = bufnr }

    vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

    -- auto show diagnostic when cursor hold
    vim.api.nvim_create_autocmd("CursorHold", {
      buffer = bufnr,
      callback = function()
        local float_opts = {
          focusable = false,
          close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        }

        if not vim.b.diagnostics_pos then
          vim.b.diagnostics_pos = { nil, nil }
        end

        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        if (cursor_pos[1] ~= vim.b.diagnostics_pos[1] or cursor_pos[2] ~= vim.b.diagnostics_pos[2])
          and #vim.diagnostic.get() > 0
        then
          vim.diagnostic.open_float(nil, float_opts)
        end

        vim.b.diagnostics_pos = cursor_pos
      end,
    })
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

  local setup_server = function(server, config)
    if not config then
      return
    end

    if type(config) ~= "table" then
      config = {}
    end

    config = vim.tbl_deep_extend("force", {
      on_attach = on_attach,
      capabilities = capabilities,
    }, config)

    require("lspconfig")[server].setup(config)
  end

  for server, config in pairs(servers) do
    setup_server(server, config)
  end
end

local lsp_formatting = function(bufnr)
  vim.lsp.buf.format({
    filter = function(client)
      return client.name == "null-ls"
    end,
    bufnr = bufnr,
  })
end

return {
  -- configuration for nvim lsp
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {

      -- for develop neovim
      {
        "folke/neodev.nvim",
        config = function()
          require("neodev").setup()
        end
      },

      -- nvim-cmp source for neovim's built-in LSP
      {
        "hrsh7th/cmp-nvim-lsp",
      },

      -- Use Neovim as a language server to inject LSP
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require("null-ls").setup {
            sources = {
              require("null-ls").builtins.formatting.prettierd,
              -- null_ls.builtins.diagnostics.eslint_d,
            },
            on_attach = function(client, bufnr)
              if client.supports_method("textDocument/formatting") then
                if format_on_save then
                  -- auto formatting on save
                  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
                  vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                  vim.api.nvim_create_autocmd("BufWritePre", {
                    group = augroup,
                    buffer = bufnr,
                    callback = function()
                      lsp_formatting(bufnr)
                    end
                  })
                end
                vim.api.nvim_create_user_command("Format", function()
                  lsp_formatting(bufnr)
                end, {})
              end
            end
          }
        end
      },
    },
    config = function()
      lsp_related_ui_adjust()
      lspconfig_setup()

    end
  },

  -- managing tool for lsp
  {
    "williamboman/mason.nvim",
    dependencies = {
      -- bridges mason with the lspconfig
      {
        "williamboman/mason-lspconfig.nvim",
        config = function()
          require("mason-lspconfig").setup {
            ensure_installed = vim.tbl_keys(servers)
          }
        end
      },

      -- bridges mason.nvim with the null-ls plugin
      {
        "jay-babu/mason-null-ls.nvim",
        config = function()
          require("mason-null-ls").setup {
            ensure_installed = {
              "prettierd",
            },
          }
        end
      },
    },
    config = function()
      require("mason").setup {
        providers = {
          "mason.providers.registry-api", -- default
          "mason.providers.client",
        },
        ui = {
          height = 0.85,
          border = "rounded",
        }
      }
    end
  },
}
