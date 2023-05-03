local linters = require("plugins.linting.linters")
local sources = {} -- a list of to_register_wrap
for linter, setting in pairs(linters) do
  if not setting.disabled then
    sources[linter] = setting.to_register_wrap
  end
end

return {
  "jose-elias-alvarez/null-ls.nvim",
  opts = sources, -- passed to the parent spec's config()
}
