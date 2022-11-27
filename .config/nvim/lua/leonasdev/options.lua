local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

--search & replace settings
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- show substitute results in preview window
-- opt.hlsearch = false -- do not hightlight all search result

-- appearance
opt.termguicolors = true -- true color
opt.background = "dark"
opt.cursorline = true
opt.pumblend = 10 -- transparency for popup-menu
vim.api.nvim_set_hl(0, 'WinSeparator', { bg = 'None' }) -- the line background between two windows

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
-- allow you to yank from neovim and C-v to anywhere vice versa
opt.clipboard:prepend { 'unnamed', 'unnamedplus' }

-- split windows
opt.splitright = true -- new vertical splits will appear on the right
opt.splitbelow = true -- new horizontal splits will appear on the bottom

-- encodings
vim.scriptencoding = 'utf-8'
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8'

-- persistance undo
opt.undofile = true

-- others
opt.iskeyword:append("-") -- now 'test-test' is a word
opt.scrolloff = 10
opt.path:append { '**' } -- Finding files - Search down into subfolders
opt.updatetime = 100 -- ref: https://www.reddit.com/r/vim/comments/jqogan/how_does_a_lower_updatetime_lead_to_better/

-- Highlight yanked text
local ag = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd
au('TextYankPost', {
  group = ag('yank_highlight', {}),
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup = 'Search',
      timeout = 100 }
  end,
})
