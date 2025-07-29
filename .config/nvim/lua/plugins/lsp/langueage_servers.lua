local M = {}

M.servers = {
  lua_ls = { enabled = true },
  pyright = {
    enabled = true,
    config = {
      settings = {
        python = {
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
    },
  },
  gopls = { enabled = false },
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
