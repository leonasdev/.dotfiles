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
-- opt.wrap = true
-- opt.breakindent = true
-- opt.showbreak = string.rep(" ", 3) -- Make it so that long lines wrap smartly
-- opt.linebreak = true

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
if _G.IS_WSL then -- you need put win32yank in system32
    vim.g.clipboard = {
        name = 'win32yank-wsl',
        copy = {
            ["+"] = { "win32yank.exe", "-i", "--crlf" },
            ["*"] = { "win32yank.exe", "-i", "--crlf" },
        },
        paste = {
            ["+"] = { "win32yank.exe", "-o", "--lf" },
            ["*"] = { "win32yank.exe", "-o", "--lf" },
        },
        cache_enabled = true
    }
end

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
opt.belloff = "all" -- Just turn the dang bell off
opt.signcolumn = "yes" -- always showing the signcolumn

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('yank_highlight', {}),
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup = 'Search',
      timeout = 100 }
  end,
})
