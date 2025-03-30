local Util = require("lazy.core.util")

local M = {}

M.autoformat = true

function M.toggle()
  M.autoformat = not M.autoformat
  if M.autoformat then
    Util.info("Enabled formatting on save", { title = "Format" })
  else
    Util.warn("Disabled formatting on save", { title = "Format" })
  end
end

M.disable_autoformat = {
  "dockerfile",
}

return M
