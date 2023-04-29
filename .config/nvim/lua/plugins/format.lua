---@param config_names table
local function formatting_config_finder(config_names)
  local path_separator = "/"
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/format/"
  if _G.IS_WINDOWS then
    path_separator = "\\"
    config_path = vim.fn.stdpath("config") .. "\\lua\\plugins\\format\\"
  end

  -- search from current working dir
  for _, name in ipairs(config_names) do
    if vim.loop.fs_stat(vim.loop.cwd() .. path_separator .. name) then
      return vim.loop.cwd() .. path_separator .. name
    end
  end

  -- search from /lua/plugins/format/
  for _, name in ipairs(config_names) do
    if vim.loop.fs_stat(config_path .. name) then
      return config_path .. name
    end
  end

  return {}
end

local formatting_buffer = function()
  local buf = vim.api.nvim_get_current_buf()
  if require("leonasdev.autoformat").autoformat == false then
    return
  end

  local ft = vim.bo[buf].filetype
  local have_nls = #require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0

  vim.lsp.buf.format({
    bufnr = buf,
    timeout_ms = 5000,
    filter = function(client)
      if have_nls then
        return client.name == "null-ls"
      end
      return client.name ~= "null-ls"
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspFormatting", {}),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("LspAutoFormat." .. bufnr, {}),
        buffer = bufnr,
        callback = function()
          if not require("leonasdev.autoformat").autoformat then
            return
          end
          formatting_buffer()
        end,
      })

      vim.api.nvim_create_user_command("FormatToggle", function()
        require("leonasdev.autoformat").toggle()
      end, { desc = "Toggle Format on Save" })

      -- TODO: Format command in visual mode and normal mode
      -- vim.api.nvim_create_user_command("Format", format
      --   , { range = true, desc = "Format on range" })
    end
  end,
})

return {
  -- bridges mason.nvim with the null-ls plugin
  {
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function()
      local nls = require("null-ls")
      require("mason-null-ls").setup({
        ensure_installed = {
          "prettier",
          "dprint",
          "rustfmt",
          "stylua",
        },
        handlers = {
          function() end,
          rustfmt = function(source_name, methods)
            nls.register(nls.builtins.formatting.rustfmt.with({
              filetypes = { "rust" },
            }))
          end,
          prettier = function(source_name, methods)
            nls.register(nls.builtins.formatting.prettier.with({
              filetypes = { "html", "css", "scss" },
              extra_args = { "--print-width", "120" },
            }))
          end,
          dprint = function(source_name, methods)
            nls.register(nls.builtins.formatting.dprint.with({
              filetypes = {
                "javascriptreact",
                "typescript",
                "typescriptreact",
                "json",
                "javascript",
              },
              -- check if project have dprint configuration
              extra_args = { "--config", formatting_config_finder({ "dprint.json", ".dprint.json" }) },
            }))
          end,
          stylua = function(source_name, methods)
            nls.register(nls.builtins.formatting.stylua.with({
              filetypes = { "lua" },
              extra_args = { "--config-path", formatting_config_finder({ "stylua.toml", ".stylua.toml" }) },
            }))
          end,
        },
      })
    end,
  },
}
