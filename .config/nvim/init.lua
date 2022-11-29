local uname = vim.loop.os_uname()

_G.OS = uname.sysname
_G.IS_MAC = OS == 'Darwin'
_G.IS_LINUX = OS == 'Linux'
_G.IS_WINDOWS = OS:find 'Windows' and true or false
_G.IS_WSL = IS_LINUX and uname.release:find 'Microsoft' and true or false

-- Leader key -> " "
vim.g.mapleader = " "

-- Turn off builtin plugins I do not use
require('leonasdev.disable_builtin')

require('leonasdev.packer')
require('leonasdev.options')
require('leonasdev.keymaps')
