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

vim.g.gruvbox_material_transparent_background = 1

local status, _ = pcall(vim.cmd, "colorscheme gruvbox-material")
if not status then
  print("Colorscheme not found")
  return
end

vim.api.nvim_set_hl(0, 'GruvboxYellowSign', { link = 'GruvboxYellow' })
vim.api.nvim_set_hl(0, 'GruvboxPurpleSign', { link = 'GruvboxPurple' })
vim.api.nvim_set_hl(0, 'GruvboxOrangeSign', { link = 'GruvboxOrange' })
vim.api.nvim_set_hl(0, 'GruvboxGreenSign', { link = 'GruvboxGreen' })
vim.api.nvim_set_hl(0, 'GruvboxBlueSign', { link = 'GruvboxBlue' })
vim.api.nvim_set_hl(0, 'GruvboxAquaSign', { link = 'GruvboxAqua' })
vim.api.nvim_set_hl(0, 'GruvboxRedSign', { link = 'GruvboxRed' })
-- vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'GruvboxRed' })
-- vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { link = 'GruvboxYellow' })
-- vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { link = 'GruvboxBlue' })
-- vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { link = 'GruvboxAqua' })

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
