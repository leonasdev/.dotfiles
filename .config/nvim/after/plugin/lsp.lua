local lspconfig = require("lspconfig")
local fidget = require("fidget")
local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")

-- local status2, lspsaga = pcall(require, "lspsaga")
-- if (not status2) then
--   return
-- end

fidget.setup{
  window = {
    blend = 0 -- set 0 if using transparent background, otherwise set 100
  }
}

mason.setup {
  providers = {
    "mason.providers.registry-api",
    "mason.providers.client",
  },
  ui = {
    border = "rounded",
    height = 0.8,
  }
}

require("lspconfig.ui.windows").default_options.border = "rounded"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded"
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded"
})

vim.diagnostic.config {
  float = { border = "rounded" },
}

-- auto formatting when save file
local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })
local enable_format_on_save = function(_, bufnr)
  vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup_format,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ bufnr = bufnr })
    end,
  })
end

local on_attach = function(_, bufnr)
  -- enable format on save in all configred lsp
  -- enable_format_on_save(client, bufnr)

  -- lspsaga.setup({
  --   ui = {
  --     title = false,
  --     border = "rounded",
  --     colors = {
  --       normal_bg = "",
  --     },
  --   },
  --   symbol_in_winbar = {
  --     enable = false,
  --   },
  --   rename = {
  --     quit = '<Esc>',
  --   },
  --   definition = {
  --     quit = '<Esc>',
  --   },
  --   code_action = {
  --     keys = {
  --       quit = '<Esc>',
  --       exec = '<CR>'
  --     },
  --   },
  --   lightbulb = {
  --     enable = false,
  --   },
  --   diagnostic = {
  --     show_code_action = false,
  --     show_source = false,
  --   },
  --   request_timeout = 50000,
  -- })

  -- Mappings.

  -- vim.keymap.set('n', '<leader>dn', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts) -- jump to next diagnostic
  -- vim.keymap.set('n', '<leader>dp', '<Cmd>Lspsaga diagnostic_jump_prev<CR>', opts) -- jump to previous diagnostic
  -- vim.keymap.set('n', '<leader>dd', '<Cmd>Lspsaga show_line_diagnostics<CR>', opts) -- show current line diagnostics
  -- vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', opts) -- show definitions, implementations, references
  -- vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', opts) -- show definition and make edits in float window
  -- vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', opts) -- show docs for what is under cursor
  -- vim.keymap.set('n', '<leader>rn', '<Cmd>Lspsaga rename<CR>', opts) -- smart rename
  -- vim.keymap.set('n', '<leader>ca', '<Cmd>Lspsaga code_action<CR>', opts) -- show available code actions
  -- vim.keymap.set('i', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts) -- show docs for what is under cursor in insertMode

  local opts = { buffer = bufnr }

  vim.keymap.set('n', '<leader>dn', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<leader>dp', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '<leader>dd', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gr', require("telescope.builtin").lsp_references, opts)
  vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, opts)
  -- vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>')
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local servers = {
  html = true,
  pyright = true,
  clangd = not _G.IS_WINDOWS, -- DO NOT DEVELOP C++ IN WINDOWS!
  gopls = true,
  tsserver = true,
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

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

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

  lspconfig[server].setup(config)
end

for server, config in pairs(servers) do
  setup_server(server, config)
end
