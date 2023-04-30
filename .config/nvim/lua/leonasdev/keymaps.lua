-- leader key is <Space>, defined in init.lua
local keymap = vim.keymap

keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- set q to do nothing because it's so annoying (default is recording macro)
-- turned on when you need
keymap.set("n", "q", "")

-- greatest remap ever (Paste over selection without yanking)
keymap.set("x", "p", "P")

-- using delete without yank
keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

-- escape insert mode
keymap.set("i", "jk", "<ESC>")

-- clear highlight of search
keymap.set("n", "<leader>nh", "<cmd>nohl<cr>", { desc = "Clear highlight" })

-- clear highlight of search, messages, floating windows
keymap.set({ "n", "i" }, "<Esc>", function()
  vim.cmd([[nohl]]) -- clear highlight of search
  vim.cmd([[stopinsert]]) -- clear messages (the line below statusline)
  for _, win in ipairs(vim.api.nvim_list_wins()) do -- clear all floating windows
    if vim.api.nvim_win_get_config(win).relative == "win" then
      vim.api.nvim_win_close(win, false)
    end
  end
end, { desc = "Clear highlight of search, messages, floating windows" })

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Scrolling
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- Delete a word using Ctrl+Backspace
keymap.set("i", "<C-BS>", "<C-w>")
keymap.set("c", "<C-BS>", "<C-w>")
keymap.set("i", "<C-H>", "<C-w>") -- using Ctrl+Backspace delete a word. ref:https://www.reddit.com/r/neovim/comments/prp8zw/using_ctrlbackspace_in_neovim/
keymap.set("c", "<C-H>", "<C-w>") -- using Ctrl+Backspace delete a word (command mode). ref:https://www.reddit.com/r/neovim/comments/prp8zw/using_ctrlbackspace_in_neovim/

-- Move line in visual mode
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Search and replace in current word (case sensitive)
keymap.set(
  "n",
  "<leader>s",
  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
  { desc = "Replace current word (case sensitive)" }
)
keymap.set(
  "v",
  "<leader>s",
  ":s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
  { desc = "Replace current word (case sensitive)" }
)

-- Add undo break-points
keymap.set("i", ",", ",<C-g>u")
keymap.set("i", ".", ".<C-g>u")
keymap.set("i", ";", ";<C-g>u")

-- Fix tab? (I forgot what is it for)
keymap.set("i", "<C-i>", "<C-i>")

-- Smart insert in blank line (auto indent)
keymap.set("n", "i", function()
  if #vim.fn.getline(".") == 0 then
    return [["_cc]]
  else
    return "i"
  end
end, { expr = true })

-- Mapping for dd that doesn't yank an empty line into your default register:
keymap.set("n", "dd", function()
  if vim.api.nvim_get_current_line():match("^%s*$") then
    return '"_dd'
  else
    return "dd"
  end
end, { expr = true })

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Resize window using <ctrl> arrow keys
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })
