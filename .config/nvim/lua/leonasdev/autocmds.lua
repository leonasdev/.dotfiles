-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlighting", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "Search", timeout = 100 })
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- disable auto comment when insert new line after comment
vim.api.nvim_create_autocmd("bufEnter", {
  group = vim.api.nvim_create_augroup("FormatOptions", {}),
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" })
  end,
})
