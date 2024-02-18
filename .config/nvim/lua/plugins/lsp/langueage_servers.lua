return {
  html = {
    name = "html-lsp", -- for mason installer
    disabled = false,
  },
  pyright = {
    name = "pyright",
    disabled = false,
    config = {
      root_dir = function(fname)
        return require("lspconfig.util").root_pattern(".git")(fname)
      end,
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
  clangd = {
    name = "clangd",
  },
  gopls = {
    name = "gopls",
  },
  tsserver = {
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
  lua_ls = {
    name = "lua-language-server",
    config = {
      settings = {
        Lua = {
          diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = { "vim" },
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            -- library = vim.api.nvim_get_runtime_file("", true),
            library = {
              vim.fn.stdpath("config"),
            },
            checkThirdParty = false,
          },
          -- Do not send telemetry data containing a randomized but unique identifier
          telemetry = {
            enable = false,
          },
        },
      },
    },
  },
  solidity = {
    name = "nomicfoundation-solidity-language-server",
    config = {
      cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
      filetypes = { "solidity" },
      single_file_support = true,
    },
  },
  dockerls = {
    name = "dockerfile-language-server",
  },
}
