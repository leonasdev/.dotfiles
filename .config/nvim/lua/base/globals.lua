local uname = vim.loop.os_uname()

_G.OS = uname.sysname
_G.IS_MAC = OS == "Darwin"
_G.IS_LINUX = OS == "Linux"
_G.IS_WINDOWS = OS:find("Windows") and true or false
_G.IS_WSL = (function()
  local output = vim.fn.systemlist("uname -r")
  local condition1 = IS_LINUX and uname.release:lower():find("microsoft") and true or false
  local condition2 = not not string.find(output[1] or "", "WSL")
  return condition1 or condition2
end)()

-- Wrapper of print + vim.inspect
P = function(v)
  print(vim.inspect(v))
  return v
end
