-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlighting", { clear = true }),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 100 })
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("LastLoc", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- disable auto comment when insert new line after comment
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("FormatOptions", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" })
  end,
})

-- instantly hide diagnostic when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
  group = vim.api.nvim_create_augroup("HideDiagnostic", { clear = true }),
  pattern = "*",
  callback = function()
    vim.diagnostic.hide(nil, 0)
  end,
})

-- instantly show diagnostic when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  group = vim.api.nvim_create_augroup("ShowDiagnostic", { clear = true }),
  pattern = "*",
  callback = function()
    vim.diagnostic.show(nil, 0)
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = vim.api.nvim_create_augroup("resize_splits", { clear = true }),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})
