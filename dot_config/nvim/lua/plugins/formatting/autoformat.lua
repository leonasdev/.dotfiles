local Util = require("lazy.core.util")

local M = {}

M.autoformat = true

function M.toggle()
  if vim.b.autoformat == false then
    vim.b.autoformat = nil
    M.autoformat = true
  else
    M.autoformat = not M.autoformat
  end
  if M.autoformat then
    Util.info("Enabled formatting on save", { title = "Format" })
  else
    Util.warn("Disabled formatting on save", { title = "Format" })
  end
end

return M
