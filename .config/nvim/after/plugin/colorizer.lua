local status, colorizer = pcall(require, 'colorizer')
if (not status) then
  return
end

colorizer.setup({
  user_default_options = {
    filetypes = { "*" },
    tailwind = true,
  }
})
