local uname = vim.loop.os_uname()

_G.OS = uname.sysname
_G.IS_MAC = OS == 'Darwin'
_G.IS_LINUX = OS == 'Linux'
_G.IS_WINDOWS = OS:find 'Windows' and true or false
_G.IS_WSL = (function()
    local output = vim.fn.systemlist "uname -r"
    return not not string.find(output[1] or "", "WSL")
end)()

-- Leader key -> " "
vim.g.mapleader = " "

-- Turn off builtin plugins I do not use
require('leonasdev.disable_builtin')

if not require('leonasdev.packer') then
  return
end
require('leonasdev.options')
require('leonasdev.keymaps')
