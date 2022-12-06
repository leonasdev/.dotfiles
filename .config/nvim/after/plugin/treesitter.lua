local status, configs = pcall(require, 'nvim-treesitter.configs')
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

configs.setup {
  highlight = {
    enable = true,
    disable = {}
  },
  ensure_installed = {
    -- 'vim',
    -- 'c',
    -- 'cpp',
    -- 'go',
    -- 'gomod',
    -- 'java',
    -- 'javascript',
    -- 'typescript',
    -- 'json',
    -- 'html',
    -- 'css',
    -- 'scss',
    -- 'lua',
    -- 'rust'
  },
  sync_install = true,
  auto_install = true,
  autotag = { -- dependency with 'nvim-ts-autotag'
    enable = true
  }
}

-- Must installed zig via scoop in Windows
if _G.IS_WINDOWS then
  install.compilers = { "zig" }
else
  install.compilers = { "clang", "gcc", "cc", "cl", "zig" }
end

autopairs.setup {}
