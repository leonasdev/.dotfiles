local M = {}

-- stylua: ignore
M.keys = {
  { "n", "<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Jump to Next Diagnostic" }},
  { "n", "<leader>dp", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Jump to Previous Diagnostic" }},
  { "n", "<leader>dd", vim.diagnostic.open_float, { desc = "Open Diagnostic Float" }},
  { "n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, { desc = "Hover Information" }},
  { { "i", "n" }, "<C-s>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end , { desc = "Signature Help" }},
  { "n", "<leader>rn", vim.lsp.buf.rename , { desc = "Rename All References" }},
  { "n", "<leader>ca", vim.lsp.buf.code_action , { desc = "Code Action" }},
}

function M.on_attach(buffer)
  for _, key in ipairs(M.keys) do
    key[4].buffer = buffer
    vim.keymap.set(key[1], key[2], key[3], key[4])
  end
end

return M
