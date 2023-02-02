local status, ts_configs = pcall(require, 'nvim-treesitter.configs')
if (not status) then
  return
end

local status2, install = pcall(require, 'nvim-treesitter.install')
if (not status2) then
  return
end

local status3, autopairs = pcall(require, 'nvim-autopairs')
if (not status3) then
  return
end

local status4, surround = pcall(require, 'nvim-surround')
if (not status4) then
  return
end

autopairs.setup {}

surround.setup {
  keymaps = {
    normal = "s",
    normal_cur = "ss",
  }
}

ts_configs.setup {
  highlight = {
    enable = true,
    disable = {}
  },
  indent = {
    enable = true,
  },
  ensure_installed = {
    'vim',
    -- 'c',
    'cpp',
    'go',
    'gomod',
    -- 'java',
    'javascript',
    'typescript',
    'json',
    'html',
    'css',
    -- 'scss',
    'lua',
    -- 'rust'
  },
  auto_install = true,
  autotag = { -- dependency with 'nvim-ts-autotag'
    enable = true
  },
  playground = {
      enable = true,
      disable = {},
  },
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        ["af"] = { query = "@function.outer", desc = "Select outer part of a function region" },
        ["if"] = { query = "@function.inner", desc = "Select inner part of a function region" },
        ["ac"] = { query = "@class.outer", desc = "Select outer part of a class region" },
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>xp"] = { query = "@parameter.inner", desc = "Swap parameter with the next one"},
      },
      swap_previous = {
        ["<leader>xP"] = { query = "@parameter.inner", desc = "Swap parameter with the previous one"},
      },
    },
  },
}

-- Must installed zig via scoop in Windows
if _G.IS_WINDOWS then
  install.compilers = { "zig" }
else
  install.compilers = { "clang", "gcc", "cc", "cl", "zig" }
end
