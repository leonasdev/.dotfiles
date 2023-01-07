local status, lspconfig = pcall(require, "lspconfig")
if (not status) then
  return
end

local status2, lspsaga = pcall(require, "lspsaga")
if (not status2) then
  return
end

local status3, fidget = pcall(require, "fidget")
if (not status3) then
  return
end

fidget.setup{
    window = {
        blend = 0 -- set 0 if using transparent background, otherwise set 100
    }
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

local default_on_attach = function(client, bufnr)
  -- enable format on save in all configred lsp
  -- enable_format_on_save(client, bufnr)

  lspsaga.init_lsp_saga({
    border_style = "single",
    rename_action_quit = '<Esc>',
    definition_action_keys = {
      quit = '<Esc>'
    },
    code_action_keys = {
      quit = '<Esc>',
      exec = '<CR>'
    },
    code_action_icon = " ",
    code_action_lightbulb = {
      enable = false
    },
    finder_request_timeout = 50000,
  })

  -- Mappings.
  local opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', '<leader>dn', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts) -- jump to next diagnostic
  vim.keymap.set('n', '<leader>dp', '<Cmd>Lspsaga diagnostic_jump_prev<CR>', opts) -- jump to previous diagnostic
  vim.keymap.set('n', '<leader>dd', '<Cmd>Lspsaga show_line_diagnostics<CR>', opts) -- show current line diagnostics
  vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', opts) -- show definitions, implementations, references
  vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', opts) -- show definition and make edits in float window
  vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', opts) -- show docs for what is under cursor
  vim.keymap.set('n', '<leader>rn', '<Cmd>Lspsaga rename<CR>', opts) -- smart rename
  vim.keymap.set('n', '<leader>ca', '<Cmd>Lspsaga code_action<CR>', opts) -- show available code actions
  vim.keymap.set('i', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts) -- show docs for what is under cursor in insertMode
end

local default_capabilities = require('cmp_nvim_lsp').default_capabilities()

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
          library = vim.api.nvim_get_runtime_file("", true),
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

local setup_server = function(server, config)
  if not config then
    return
  end

  if type(config) ~= "table" then
    config = {}
  end

  config = vim.tbl_deep_extend("force", {
    on_attach = default_on_attach,
    capabilities = default_capabilities,
  }, config)

  lspconfig[server].setup(config)
end

for server, config in pairs(servers) do
  setup_server(server, config)
end
