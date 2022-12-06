local status, lualine = pcall(require, 'lualine')
if (not status) then
  return
end

lualine.setup({
  options = {
    theme = 'solarized_dark',
    globalstatus = true
  }
})
