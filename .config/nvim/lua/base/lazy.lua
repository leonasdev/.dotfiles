-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Add support for the LazyFile event (ported from LazyVim)
local Event = require("lazy.core.handler.event")
Event.mappings.LazyFile = { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } }
Event.mappings["User LazyFile"] = Event.mappings.LazyFile

vim.g.maplocalleader = "\\"

local icons = require("util.icons")
-- Setup lazy.nvim
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "my-colorscheme", "solarized", "habamax" } },
  ui = {
    border = "rounded",
    icons = {
      loaded = icons.status.check,
      not_loaded = icons.status.uncheck,
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  change_detection = { notify = false },
  dev = { path = "~/personal" },
  git = { timeout = 60 },
})

-- close lazy panel with esc
require("lazy.view.config").keys.close = "<esc>"
