-- Ignore files bigger than a threshold
local new_maker = function(filepath, bufnr, opts)
  opts = opts or {}

  filepath = vim.fn.expand(filepath)
  vim.loop.fs_stat(filepath, function(_, stat)
    if not stat then return end
    if stat.size > 100000 then
      return
    else
      require("telescope.previewers").buffer_previewer_maker(filepath, bufnr, opts)
    end
  end)
end

-- configs
local enable_previewer = false

local function edit_neovim()
  local opts = {
    prompt_title = "~ Neovim Config ~",
    cwd = vim.fn.stdpath("config"),
    previewer = enable_previewer,
  }

  require('telescope.builtin').find_files(opts)
end

local function find_files_or_git_files()
  if vim.loop.fs_stat(vim.loop.cwd() .. "/.git") then
    local opts = {
      previewer = enable_previewer,
      show_untracked = true,
    }

    require("telescope.builtin").git_files(opts)
  else
    local opts = {
      previewer = enable_previewer,
      no_ignore = true, -- set false to ignore files by .gitignore
      hidden = true -- set false to ignore dotfiles
    }

    require("telescope.builtin").find_files(opts)
  end
end

local function live_grep()
  -- require('telescope.builtin').live_grep()
  require('telescope').extensions.live_grep_args.live_grep_args()
end

local function file_browser()
  require('telescope').extensions.file_browser.file_browser({
  })
end

local function current_buffer_fuzzy_find()
  require("telescope.builtin").current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    previewer = false,
  })
end

return {
  -- super powerful fuzzy-finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<C-p>", find_files_or_git_files, mode = "n", desc = "Find Files or Git Files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", mode = "n", desc = "Find Files" },
      { "<C-f>", live_grep, mode = "n", desc = "Live Grep (Args)" },
      { "<C-f>", "<cmd>Telescope grep_string<cr>", mode = "v", desc = "Grep String" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", mode = "n", desc = "Help Pages" },
      { "<leader>fe", "<cmd>Telescope diagnostics<cr>", mode = "n", desc = "Diagnostics" },
      { "<leader>fn", edit_neovim, mode = "n", desc = "Edit Neovim" },
      { "<C-n>", file_browser, mode = "n", desc = "File Browser" },
      { "<leader>hi", "<cmd>Telescope highlights<cr>", mode = "n", desc = "Neovim Highlight Groups" },
      { "<leader>/", current_buffer_fuzzy_find, mode = "n", desc = "Fuzzy Find in Current Buffer" },
      { "gr", "<cmd>Telescope lsp_references<cr>", mode = "n", desc = "LSP Find References" },
    },
    config = function()
      require("telescope").setup {
        defaults = {
          buffer_previewer_maker = new_maker,
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              ["<c-j>"] = require("telescope.actions").move_selection_next,
              ["<c-k>"] = require("telescope.actions").move_selection_previous,
              ["<c-s>"] = require("telescope.actions").select_vertical,
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

      require('telescope').load_extension('fzf')
    end
  },

  -- native telescope sorter to significantly improve sorting performance
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    lazy = true,
    build = "make",
  },

  -- file browser extension for telescope.nvim
  {
    "nvim-telescope/telescope-file-browser.nvim",
    lazy = true
  },

  -- enable passing arguments to the live_grep of telescope
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    lazy = true
  },

  -- Getting you where you want with the fewest keystrokes
  {
    "ThePrimeagen/harpoon",
    keys = {
      { "<C-e>", function() require("harpoon.ui").toggle_quick_menu() end, mode = "n", desc = "Harpoon Menu" },
      { "<leader>a", function() require("harpoon.mark").add_file() end, mode = "n", desc = "Harpoon Add File" },
      { "<C-h>", function() require("harpoon.ui").nav_file(1) end, mode = "n", desc = "Harpoon Nav File 1" },
      { "<C-j>", function() require("harpoon.ui").nav_file(2) end, mode = "n", desc = "Harpoon Nav File 2" },
      { "<C-k>", function() require("harpoon.ui").nav_file(3) end, mode = "n", desc = "Harpoon Nav File 3" },
      { "<C-l>", function() require("harpoon.ui").nav_file(4) end, mode = "n", desc = "Harpoon Nav File 4" },
    },
    config = function()
      vim.api.nvim_create_autocmd({ "Filetype" }, {
        pattern = "harpoon",
        callback = function()
          vim.opt.cursorline = true
          vim.api.nvim_set_hl(0, 'HarpoonWindow', { link = 'Normal' })
          vim.api.nvim_set_hl(0, 'HarpoonBorder', { link = 'Normal' })
        end
      })
    end
  },
}
