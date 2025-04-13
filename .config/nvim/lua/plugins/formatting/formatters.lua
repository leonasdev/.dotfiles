local M = {}

local default_config_dir = vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/"

M.formatters = {
  stylua = {
    enabled = true,
    ensure_installed = "stylua",
    fts = { "lua" },
    prepend_args = function()
      return {
        "--config-path",
        require("util").config_finder({ "stylua.toml", ".stylua.toml" }, default_config_dir),
      }
    end,
  },
  ruff_format = {
    enabled = true,
    ensure_installed = "ruff",
    fts = { "python" },
    prepend_args = function()
      return {
        "--config",
        require("util").config_finder({ "ruff.toml", "pyproject.toml" }, default_config_dir),
      }
    end,
  },
  gofumpt = {
    enabled = true,
    ensure_installed = "gofumpt",
    fts = { "go" },
  },
  fixjson = {
    enabled = true,
    ensure_installed = "fixjson",
    fts = { "json" },
  },
  prettier = {
    enabled = true,
    ensure_installed = "prettier",
    fts = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    prepend_args = { "--print-width", "120" },
  },
}

function M.get_enabled()
  local ret = {}
  for formatter, formatter_opts in pairs(M.formatters) do
    if not formatter_opts.enabled then
      goto continue
    end

    ret[formatter] = formatter_opts

    ::continue::
  end
  return ret
end

function M.formatters_by_ft()
  local formatters = M.get_enabled()
  local formatters_by_ft = {}
  for formatter, formatter_opts in pairs(formatters) do
    for _, ft in ipairs(formatter_opts.fts) do
      formatters_by_ft[ft] = formatters_by_ft[ft] or {}
      table.insert(formatters_by_ft[ft], formatter)
    end
  end
  return formatters_by_ft
end

function M.list_fts()
  local formatters = M.get_enabled()
  local fts = {}
  for _, formatter_opts in pairs(formatters) do
    vim.list_extend(fts, formatter_opts.fts)
  end
  return fts
end

function M.list_ensure_installed()
  local formatters = M.get_enabled()
  local ensure_installed = {}
  for _, formatter_opts in pairs(formatters) do
    table.insert(ensure_installed, formatter_opts.ensure_installed)
  end
  return ensure_installed
end

return M
