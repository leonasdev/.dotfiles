-- leader key is <Space>, defined in init.lua
local keymap = vim.keymap

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- set q to do nothing because it's so annoying (default is recording macro)
keymap.set("n", "q", "")

-- using delete without yank
keymap.set({ "n", "v" }, "<leader>d", "\"_d")

-- escape insert mode
keymap.set("i", "jk", "<ESC>")

-- clear highlight of search
keymap.set("n", "<leader>nh", ":nohl<CR>")

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Scrolling
keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- Delete a word using Ctrl+Backspace
keymap.set("i", "<C-H>", "<C-w>") -- using Ctrl+Backspace delete a word. ref:https://www.reddit.com/r/neovim/comments/prp8zw/using_ctrlbackspace_in_neovim/
keymap.set("c", "<C-H>", "<C-w>") -- using Ctrl+Backspace delete a word (command mode). ref:https://www.reddit.com/r/neovim/comments/prp8zw/using_ctrlbackspace_in_neovim/

-- Move line in visual mode
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Search and replace in current word (case sensitive)
keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
keymap.set("v", "<leader>s", ":s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
