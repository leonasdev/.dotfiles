if not pcall(require, 'harpoon') then
  return
end

vim.api.nvim_create_autocmd({ "Filetype" }, {
  pattern = "harpoon",
  callback = function()
    vim.opt.cursorline = true
    vim.api.nvim_set_hl(0, 'HarpoonWindow', { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'HarpoonBorder', { link = 'Normal' })
  end
})

vim.keymap.set('n', '<leader>a', function()
  require('harpoon.mark').add_file()
  print('Add buffer to harpoon')
end)
vim.keymap.set('n', '<C-e>', function() require('harpoon.ui').toggle_quick_menu() end)

vim.keymap.set('n', '<C-h>', function() require('harpoon.ui').nav_file(1) end)
vim.keymap.set('n', '<C-j>', function() require('harpoon.ui').nav_file(2) end)
vim.keymap.set('n', '<C-k>', function() require('harpoon.ui').nav_file(3) end)
vim.keymap.set('n', '<C-l>', function() require('harpoon.ui').nav_file(4) end)
