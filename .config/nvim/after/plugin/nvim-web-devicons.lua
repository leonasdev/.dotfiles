local status, icons = pcall(require, 'nvim-web-devicons')
if (not status) then
  print('nvim-web-devicons not installed')
  return
end

icons.setup({
  default = true
})
