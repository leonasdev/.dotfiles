local colorschemes = {
  'gruvbox',
  'kanagawa',
  'nightfox',
  'tokyonight',
  'catppuccin',
}

for _, cs in ipairs(colorschemes) do
  local status, _ = pcall(require, cs)
  if not status then
    return
  end
end

require('nightfox').setup({
  options = {
    transparent = true,
    styles = {
      comments = "italic"
    }
  }
})

require("gruvbox").setup({
  transparent_mode = true,
  overrides = {
    String = { italic = false }
  }
})

require("catppuccin").setup({
  transparent_background = true
})

require("tokyonight").setup {
  transparent = true,
}

require("kanagawa").setup({
  transparent = true,
  specialReturn = false,
})

-- for gruvbox-meterial
vim.g.gruvbox_material_transparent_background = 1

-- for ishan9229/solarized
vim.g.solarized_termtrans = 1

-- set colorscheme
local status, _ = pcall(vim.cmd, "colorscheme solarized")
if not status then
  print("Colorscheme not found")
  return
end

-- vim.api.nvim_set_hi for re-defined
-- cmd('highlight') for update

-- for ishan9229/solarized
vim.api.nvim_set_hl(0, 'NormalFloat', { bg='none' })
vim.api.nvim_set_hl(0, 'LineNr', { fg='#586e75', bg='none' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg='#b58900', bg='none' })
vim.api.nvim_set_hl(0, 'CursorLine', { fg='none', bg='#002b36' })
vim.api.nvim_set_hl(0, 'Visual', { fg='#002b36', bg='#586e75'})
vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { fg='#dc322f', bg='#360909'})
vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextWarn', { fg='#b58900', bg='#1c1500'})
vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextInfo', { fg='#268bd2', bg='#0e3550'})
vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextHint', { fg='#2aa198', bg='#0a2725'})
vim.cmd('highlight GitSignsAdd guibg=none')
vim.cmd('highlight GitSignsChange guibg=none')
vim.cmd('highlight GitSignsDelete guibg=none')

-- for gruvbox colorscheme
vim.api.nvim_set_hl(0, 'GruvboxYellowSign', { link = 'GruvboxYellow' })
vim.api.nvim_set_hl(0, 'GruvboxPurpleSign', { link = 'GruvboxPurple' })
vim.api.nvim_set_hl(0, 'GruvboxOrangeSign', { link = 'GruvboxOrange' })
vim.api.nvim_set_hl(0, 'GruvboxGreenSign', { link = 'GruvboxGreen' })
vim.api.nvim_set_hl(0, 'GruvboxBlueSign', { link = 'GruvboxBlue' })
vim.api.nvim_set_hl(0, 'GruvboxAquaSign', { link = 'GruvboxAqua' })
vim.api.nvim_set_hl(0, 'GruvboxRedSign', { link = 'GruvboxRed' })

-- local status, neosolarized = pcall(require, "neosolarized")
-- if (not status) then
--   print("neosolarized or colorbuddy not install")
--   return
-- end
--
-- neosolarized.setup()
--
-- -- colorbuddy
-- local Color, colors, Group, groups, styles = require("colorbuddy").setup()
--
-- Group.new('CursorLine', colors.none, colors.base03, styles.none, colors.base1)
-- Group.new('CursorLineNr', colors.yellow, colors.none, styles.none, colors.base1)
-- Group.new('@variable', colors.base1, colors.none, styles.none, colors.base1)
