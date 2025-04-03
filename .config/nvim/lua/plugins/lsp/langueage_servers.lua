return {
  lua_ls = {
    name = "lua-language-server",
  },
  pyright = {
    name = "pyright",
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
    name = "html-lsp", -- for mason installer
    disabled = false,
  },
  clangd = {
    name = "clangd",
    config = {
      cmd = { "clangd", "--offset-encoding=utf-16" },
    },
  },
  gopls = {
    name = "gopls",
  },
  dockerls = {
    name = "dockerfile-language-server",
  },
  rust_analyzer = {
    name = "rust-analyzer",
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
  ts_ls = {
    name = "typescript-language-server",
  },
  cssls = {
    name = "css-lsp",
  },
  jsonls = {
    name = "json-lsp",
  },
  volar = {
    name = "vue-language-server",
  },
  tailwindcss = {
    name = "tailwindcss-language-server",
  },
  astro = {
    name = "astro-language-server",
  },
  solidity = {
    name = "nomicfoundation-solidity-language-server",
    config = {
      cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
      filetypes = { "solidity" },
      single_file_support = true,
    },
  },
}
