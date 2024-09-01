local cpp = require("plugins.langs.cpp")

local merged = {}
for k, v in pairs(cpp) do
  merged[k] = v
end

return merged
