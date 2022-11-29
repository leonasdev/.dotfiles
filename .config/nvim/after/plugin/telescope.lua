if not pcall(require, 'telescope') then
  return
end

local actions = require('telescope.actions')

-- setup
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<c-j>"] = actions.move_selection_next,
        ["<c-k>"] = actions.move_selection_previous,
        ["<c-s>"] = actions.select_vertical,
      }
    }
  },
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case", -- or "ignore_case" or "respect_case", the default case_mode is "smart_case"
    },
    file_browser = {
      previewer = false,
      theme = "dropdown",
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = true,
      mappings = {
        i = {
          ["<esc>"] = false
        }
      }
    }
  }
}

-- require('telescope').load_extension('fzf')
require('telescope').load_extension('file_browser')
require('telescope').load_extension('live_grep_args')

-- configs
local function edit_neovim()
  local opts = {
    prompt_title = "~ Neovim Config ~",
    cwd = vim.fn.stdpath("config"),
  }

  require('telescope.builtin').find_files(opts)
end

local function find_files()
  local opts = {
    no_ignore = true, -- set false to ignore files by .gitignore
    hidden = true -- set false to ignore dotfiles
  }

  require('telescope.builtin').find_files(opts)
end

local function git_files()
  require('telescope.builtin').git_files()
end

local function live_grep()
  -- require('telescope.builtin').live_grep()
  require('telescope').extensions.live_grep_args.live_grep_args()
end

local function grep_string()
  require('telescope.builtin').grep_string()
end

local function buffers()
  require('telescope.builtin').buffers()
end

local function help_tags()
  require('telescope.builtin').help_tags()
end

local function diagnostics()
  require('telescope.builtin').diagnostics()
end

local function file_browser()
  require('telescope').extensions.file_browser.file_browser({
  })
end

-- mappings
vim.keymap.set('n', '<leader>ff', find_files, {})
vim.keymap.set('n', '<C-f>', live_grep, {})
vim.keymap.set('v', '<C-f>', grep_string, {})
vim.keymap.set('n', '<leader>fb', buffers, {})
vim.keymap.set('n', '<leader>fh', help_tags, {})
vim.keymap.set('n', '<C-p>', function() -- use git_file if in working tree. if not, using find_file
  vim.fn.system('git rev-parse --is-inside-work-tree')
  if vim.v.shell_error == 0 then
    git_files()
  else
    find_files()
  end
end
  , {})
vim.keymap.set('n', '<leader>fe', diagnostics, {})

vim.keymap.set('n', '<leader>fn', edit_neovim, {})

vim.keymap.set('n', '<C-n>', file_browser, {})
