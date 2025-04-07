local Util = require("lazy.core.util")

local M = {}

M.autoformat = true

function M.toggle()
  local ft = vim.api.nvim_get_option_value("filetype", {})
  if vim.tbl_contains(require("plugins.formatting.autoformat").disable_autoformat_ft, ft) then
    Util.warn("Could not enable auto-format for filetype: '" .. ft .. "' (in disable_autoformat_ft list)")
    return
  end
  M.autoformat = not M.autoformat
  if M.autoformat then
    Util.info("Enabled formatting on save", { title = "Format" })
  else
    Util.warn("Disabled formatting on save", { title = "Format" })
  end
end

M.disable_autoformat_ft = {
  "dockerfile",
  "c",
  "cpp",
}

return M
