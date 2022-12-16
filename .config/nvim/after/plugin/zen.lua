local status, zen = pcall(require, "zen-mode")
if not status then
    return
end

zen.setup({
})
vim.api.nvim_set_hl(0, 'ZenBg', { ctermbg=0 })

vim.keymap.set("n", "<leader>z", zen.toggle)
