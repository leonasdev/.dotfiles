local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true

-- line wrapping
opt.wrap = true
-- opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
opt.linebreak = true

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--search & replace settings
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- show substitute results in preview window

-- appearance
opt.termguicolors = true -- true color
opt.cursorline = true
-- opt.pumblend = 10 -- transparency for popup-menu

-- split windows
opt.splitright = true -- new vertical splits will appear on the right
opt.splitbelow = true -- new horizontal splits will appear on the bottom

-- persistance undo
opt.undofile = true

opt.iskeyword:append("-") -- now 'test-test' is a word
opt.path:append({ "**" }) -- Finding files - Search down into subfolders
opt.updatetime = 100 -- ref: https://www.reddit.com/r/vim/comments/jqogan/how_does_a_lower_updatetime_lead_to_better/
opt.belloff = "all" -- Just turn the dang bell off
opt.signcolumn = "yes" -- always showing the signcolumn
opt.guicursor = "a:block"
