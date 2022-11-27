local status, lualine = pcall(require, 'lualine')
if (not status) then
  print('lualine not installed')
  return
end

lualine.setup({
  options = {
    theme = 'gruvbox-material',
    globalstatus = true
  }
})
