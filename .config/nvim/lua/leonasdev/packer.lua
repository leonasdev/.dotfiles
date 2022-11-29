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

return require('packer').startup { function(use)
  use 'wbthomason/packer.nvim'

  use 'nvim-lua/plenary.nvim' -- lua library for neovim

  ------ Color Schemes ------
  use 'EdenEast/nightfox.nvim'
  use 'ellisonleao/gruvbox.nvim'
  use {
    'svrana/neosolarized.nvim',
    requires = { 'tjdevries/colorbuddy.nvim' }
  }
  use 'catppuccin/nvim'
  use 'folke/tokyonight.nvim'
  use 'sainnhe/gruvbox-material'
  ---------------------------

  use 'kyazdani42/nvim-web-devicons' -- nerd font supported icons
  use 'nvim-lualine/lualine.nvim' -- status line
  use 'numToStr/Comment.nvim' -- commenting
  use 'norcalli/nvim-colorizer.lua' -- color highlighter
  use 'lewis6991/gitsigns.nvim' -- git decorations

  ------ LSP ------
  use 'neovim/nvim-lspconfig' -- configuration for nvim lsp

  use 'williamboman/mason.nvim' -- managing tool for lsp
  use 'williamboman/mason-lspconfig.nvim' -- bridges mason with the lspconfig

  use 'onsails/lspkind-nvim' -- vscode-like pictograms
  use {
    'glepnir/lspsaga.nvim', -- LSP UIs
    branch = "main"
  }

  use 'hrsh7th/cmp-buffer' -- nvim-cmp source for buffer words
  use 'hrsh7th/cmp-path' -- nvim-cmp source for path words
  use 'hrsh7th/cmp-nvim-lsp' -- nvim-cmp source for neovim's built-in LSP
  use 'hrsh7th/nvim-cmp' -- Completion
  use 'L3MON4D3/LuaSnip' -- Snippet engine
  -----------------

  use {
    'nvim-treesitter/nvim-treesitter', -- Syntax highlightings
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end
  }

  use 'windwp/nvim-autopairs'
  use { 'windwp/nvim-ts-autotag', after='nvim-treesitter' }

  ------ telescope ------
  use {
    'nvim-telescope/telescope.nvim', branch = '0.1.x', -- super powerful fuzzy-finder
  }
  -- use {
  --   'nvim-telescope/telescope-fzf-native.nvim', -- native telescope sorter to significantly improve sorting performance
  --   run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
  -- }
  use 'nvim-telescope/telescope-file-browser.nvim' -- file browser extension for telescope.nvim
  use 'nvim-telescope/telescope-live-grep-args.nvim' -- enable passing arguments to the live_grep of telescope
  -----------------------

  use 'ThePrimeagen/harpoon' -- Getting you where you want with the fewest keystrokes.


  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()

    print '=================================='
    print '    Plugins are being installed'
    print '    Wait until Packer completes,'
    print '       then restart nvim'
    print '=================================='
  end
end }
