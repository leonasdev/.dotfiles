-- Automatically source and re-compile packer whenever you save this file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer.lua source <afile> | PackerSync
  augroup end
]])

local ensure_packer = function()
  local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup { function(use)
  use 'wbthomason/packer.nvim'

  use 'nvim-lua/plenary.nvim' -- lua library for neovim
  use { 'folke/neodev.nvim', config = function ()
    require('neodev').setup()
  end}

  ------ Color Schemes ------
  use {
      'svrana/neosolarized.nvim',
      requires = { 'tjdevries/colorbuddy.nvim' }
    }
  use 'EdenEast/nightfox.nvim'
  use 'ellisonleao/gruvbox.nvim'
  use 'catppuccin/nvim'
  use 'folke/tokyonight.nvim'
  use 'sainnhe/gruvbox-material'
  use 'ishan9299/nvim-solarized-lua'
  use 'rebelot/kanagawa.nvim'
  use 'Mofiqul/vscode.nvim'
  ---------------------------

  use 'kyazdani42/nvim-web-devicons' -- nerd font supported icons
  use 'nvim-lualine/lualine.nvim' -- status line
  use 'numToStr/Comment.nvim' -- commenting
  use 'NvChad/nvim-colorizer.lua' -- color highlighter
  use 'lewis6991/gitsigns.nvim' -- git decorations

  ------ LSP ------
  use 'neovim/nvim-lspconfig' -- configuration for nvim lsp

  use 'williamboman/mason.nvim' -- managing tool for lsp
  use 'williamboman/mason-lspconfig.nvim' -- bridges mason with the lspconfig

  use 'onsails/lspkind-nvim' -- vscode-like pictograms
  -- use { -- deprecate untill it stable
  --   'glepnir/lspsaga.nvim', -- LSP UIs
  --   branch = "main"
  -- }

  use 'hrsh7th/cmp-buffer' -- nvim-cmp source for buffer words
  use 'hrsh7th/cmp-path' -- nvim-cmp source for path words
  use 'hrsh7th/cmp-nvim-lsp' -- nvim-cmp source for neovim's built-in LSP
  use 'hrsh7th/nvim-cmp' -- Completion
  use 'saadparwaiz1/cmp_luasnip' -- luasnip completion source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippet engine
  use "rafamadriz/friendly-snippets" -- Set of preconfigured snippets for different languages.
  -----------------

  use {
    'nvim-treesitter/nvim-treesitter', -- Syntax highlightings
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end
  }
  use 'nvim-treesitter/playground'

  use 'windwp/nvim-autopairs'
  use { 'windwp/nvim-ts-autotag', after='nvim-treesitter' }

  ------ telescope ------
  use {
    'nvim-telescope/telescope.nvim', branch = '0.1.x', -- super powerful fuzzy-finder
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim', -- native telescope sorter to significantly improve sorting performance
    run = 'make'
  }
  use 'nvim-telescope/telescope-file-browser.nvim' -- file browser extension for telescope.nvim
  use 'nvim-telescope/telescope-live-grep-args.nvim' -- enable passing arguments to the live_grep of telescope
  -----------------------

  use 'ThePrimeagen/harpoon' -- Getting you where you want with the fewest keystrokes.

  use 'dstein64/vim-startuptime' -- benchmark for neovim startup
  use 'folke/zen-mode.nvim' -- Distraction-free coding for Neovim
  use 'j-hui/fidget.nvim' -- Standalone UI for nvim-lsp progress

  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end }

if packer_bootstrap then
  print '=================================='
  print '    Plugins are being installed'
  print '    Wait until Packer completes,'
  print '       then restart nvim'
  print '=================================='

  return false
end

return true
