---@param config_names table
local function formatting_config_finder(config_names)
  local path_separator = "/"
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/"
  if _G.IS_WINDOWS then
    path_separator = "\\"
    config_path = vim.fn.stdpath("config") .. "\\lua\\plugins\\formatting\\configs\\"
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

local nls = require("null-ls")

return {
  rustfmt = {
    name = "rustfmt", -- for mason installer
    handler = function(source_name, methods)
      nls.register(nls.builtins.formatting.rustfmt.with({
        filetypes = { "rust" },
      }))
    end,
  },
  prettier = {
    name = "prettier",
    handler = function(source_name, methods)
      nls.register(nls.builtins.formatting.prettier.with({
        filetypes = { "html", "css", "scss" },
        extra_args = { "--print-width", "120" },
      }))
    end,
  },
  dprint = {
    name = "dprint",
    handler = function(source_name, methods)
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
  },
  stylua = {
    name = "stylua",
    handler = function(source_name, methods)
      nls.register(nls.builtins.formatting.stylua.with({
        filetypes = { "lua" },
        extra_args = { "--config-path", formatting_config_finder({ "stylua.toml", ".stylua.toml" }) },
      }))
    end,
  },
}
