return {
  lua_ls = {},
  pyright = {
    disabled = false,
    config = {
      root_dir = function(fname) return require("lspconfig.util").root_pattern(".git")(fname) end,
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
  html = {
    disabled = false,
  },
  clangd = {
    config = {
      cmd = { "clangd", "--offset-encoding=utf-16" },
    },
  },
  gopls = {},
  dockerls = {},
  rust_analyzer = {
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
  ts_ls = {},
  cssls = {},
  jsonls = {},
  volar = {},
  tailwindcss = {},
  astro = {},
  solidity = {
    config = {
      cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
      filetypes = { "solidity" },
      single_file_support = true,
    },
  },
}
