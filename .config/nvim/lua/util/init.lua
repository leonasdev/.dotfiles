local M = {}

---A helper function to find configurations
---@param config_names string[] A list of config names you want to find (e.g. { ".stylua.toml", "stylua.toml" })
---@param default_dir string Default config directory (e.g. vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/")
---@return string config_dir The directory of first found configuration (project's config > default's config)
M.config_finder = function(config_names, default_dir)
  -- prevent that user not provide last seperator
  if string.sub(default_dir, string.len(default_dir)) ~= "/" then
    default_dir = default_dir .. "/"
  end

  local config_dir = ""

  -- search from project recursively
  for _, name in ipairs(config_names) do
    local found_root = require("lspconfig").util.root_pattern(name)(vim.loop.cwd())
    if found_root then
      config_dir = found_root .. "/" .. name
      if _G.IS_WINDOWS then
        config_dir = string.gsub(config_dir, "/", "\\\\")
      end
      return config_dir
    end
  end

  -- search from defalut_dir
  for _, name in ipairs(config_names) do
    if vim.loop.fs_stat(default_dir .. name) then
      config_dir = default_dir .. name
      if _G.IS_WINDOWS then
        config_dir = string.gsub(config_dir, "/", "\\\\")
      end
      return config_dir
    end
  end

  return config_dir
end

return M
