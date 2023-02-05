local uname = vim.loop.os_uname()

_G.OS = uname.sysname
_G.IS_MAC = OS == 'Darwin'
_G.IS_LINUX = OS == 'Linux'
_G.IS_WINDOWS = OS:find 'Windows' and true or false
_G.IS_WSL = (function()
    local output = vim.fn.systemlist "uname -r"
    local condition1 = IS_LINUX and uname.release:lower():find 'microsoft' and true or false
    local condition2 = not not string.find(output[1] or "", "WSL")
    return condition1 or condition2
end)()

-- Mapping leader key to: " "
vim.g.mapleader = " "

require("leonasdev.options")
require("leonasdev.keymaps")

-- Install lazy.nvim (package manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  install = {
    colorscheme = { "solarized", "habamax" }
  },
  ui = {
    border = "rounded",
  }
})
