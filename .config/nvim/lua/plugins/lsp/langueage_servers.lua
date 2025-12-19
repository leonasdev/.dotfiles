local M = {}

local python_ls = "basedpyright"

M.servers = {
  lua_ls = { enabled = true },
  pyright = {
    enabled = python_ls == "pyright",
    config = {
      settings = {
        python = {
          analysis = {
            diagnosticMode = "openFilesOnly",
            typeCheckingMode = "off",
          },
        },
      },
      handlers = {
        -- Temporarily work around for this pyright issue, see:
        -- https://github.com/neovim/neovim/issues/34731
        -- https://github.com/microsoft/pyright/issues/10671
        [vim.lsp.protocol.Methods.textDocument_rename] = function(err, result, ctx)
          if err then
            vim.notify("Pyright rename failed: " .. err.message, vim.log.levels.ERROR)
            return
          end

          ---@cast result lsp.WorkspaceEdit
          for _, change in ipairs(result.documentChanges or {}) do
            for _, edit in ipairs(change.edits or {}) do
              if edit.annotationId then
                edit.annotationId = nil
              end
            end
          end

          local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
          vim.lsp.util.apply_workspace_edit(result, client.offset_encoding)
        end,
      },
    },
  },
  basedpyright = {
    enabled = python_ls == "basedpyright",
    config = {
      settings = {
        basedpyright = {
          analysis = {
            diagnosticMode = "openFilesOnly",
            typeCheckingMode = "off",
          },
        },
      },
    },
  },
  clangd = {
    enabled = true,
    config = {
      cmd = { "clangd", "--offset-encoding=utf-16" },
      -- prevent macro being highlighted as comment
      on_attach = function(client) client.server_capabilities.semanticTokensProvider = nil end,
    },
  },
  gopls = { enabled = true },
  rust_analyzer = {
    enabled = true,
    config = {
      settings = {
        ["rust-analyzer"] = {
          diagnostics = {
            enable = true,
            experimental = {
              enable = true,
            },
          },
        },
      },
    },
  },
  dockerls = { enabled = true },
  bashls = { enabled = true },
  jsonls = { enabled = true },
  html = { enabled = false },
  ts_ls = { enabled = false },
  cssls = { enabled = false },
  tailwindcss = { enabled = false },
}

function M.get_enabled()
  local ret = {}
  for server, server_opts in pairs(M.servers) do
    if not server_opts.enabled then
      goto continue
    end

    ret[server] = server_opts

    ::continue::
  end
  return ret
end

return M
