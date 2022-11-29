local status, icons = pcall(require, 'nvim-web-devicons')
if (not status) then
  return
end

icons.setup({
  default = true
})
