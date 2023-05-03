local function lsp_related_ui_adjust()
  require("lspconfig.ui.windows").default_options.border = "rounded"
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
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

local function lspconfig_setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      local opts = { buffer = bufnr }

      vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, opts)
      vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set({ "i", "n" }, "<C-s>", vim.lsp.buf.signature_help, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

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
          if
            (cursor_pos[1] ~= vim.b.diagnostics_pos[1] or cursor_pos[2] ~= vim.b.diagnostics_pos[2])
            and #vim.diagnostic.get() > 0
          then
            vim.diagnostic.open_float(nil, float_opts)
          end

          vim.b.diagnostics_pos = cursor_pos
        end,
      })
    end,
  })

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

  local setup_server = function(server, config)
    if not config then
      return
    end

    if type(config) ~= "table" then
      config = {}
    end

    config = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
    }, config)

    require("lspconfig")[server].setup(config)
  end

  local servers = require("plugins.lsp.langueage_servers")
  for server, setting in pairs(servers) do
    if setting.disabled then
      goto continue
    end

    if setting.config ~= nil then
      setup_server(server, setting.config)
    else
      setup_server(server, {})
    end

    ::continue::
  end
end

return {
  -- configuration for nvim lsp
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {

      -- for develop neovim
      {
        "folke/neodev.nvim",
        config = function()
          require("neodev").setup()
        end,
      },

      -- managing tool
      { "williamboman/mason.nvim" },

      -- bridges mason with the lspconfig
      { "williamboman/mason-lspconfig.nvim" },

      -- nvim-cmp source for neovim's built-in LSP
      { "hrsh7th/cmp-nvim-lsp" },
    },
    config = function()
      lsp_related_ui_adjust()
      lspconfig_setup()
    end,
  },
}
