local MAX_RESULT = 2000

-- Ignore files bigger than a threshold
local new_maker = function(filepath, bufnr, opts)
  opts = opts or {}

  filepath = vim.fn.expand(filepath)
  vim.loop.fs_stat(filepath, function(_, stat)
    if not stat then
      return
    end
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

  require("telescope.builtin").find_files(opts)
end

local function find_files_or_git_files()
  if vim.loop.fs_stat(vim.loop.cwd() .. "/.git") then
    local opts = {
      previewer = enable_previewer,
      show_untracked = false,
      recurse_submodules = true,
      temp__scrolling_limit = MAX_RESULT,
    }

    require("telescope.builtin").git_files(opts)
  else
    local opts = {
      previewer = enable_previewer,
      no_ignore = true, -- set false to ignore files by .gitignore
      hidden = true, -- set false to ignore dotfiles
      temp__scrolling_limit = MAX_RESULT,
    }

    require("telescope.builtin").find_files(opts)
  end
end

local function find_files()
  local opts = {
    previewer = enable_previewer,
    no_ignore = true, -- set false to ignore files by .gitignore
    hidden = false, -- set false to ignore dotfiles
    temp__scrolling_limit = MAX_RESULT,
  }

  require("telescope.builtin").find_files(opts)
end

local function grep_string()
  require("telescope.builtin").grep_string({
    temp__scrolling_limit = MAX_RESULT,
  })
end

local function live_grep()
  -- require('telescope.builtin').live_grep()
  require("telescope").extensions.live_grep_args.live_grep_args()
end

local function highlights()
  require("telescope.builtin").highlights({
    temp__scrolling_limit = MAX_RESULT,
  })
end

local function help_tags()
  require("telescope.builtin").help_tags({
    temp__scrolling_limit = MAX_RESULT,
  })
end

local function current_buffer_fuzzy_find()
  require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    previewer = false,
  }))
end

local function lsp_definitions()
  require("telescope.builtin").lsp_definitions(require("telescope.themes").get_dropdown({
    show_line = false,
  }))
end

local function lsp_references()
  require("telescope.builtin").lsp_references(require("telescope.themes").get_dropdown({
    show_line = false,
  }))
end

local function lsp_implementations()
  require("telescope.builtin").lsp_implementations(require("telescope.themes").get_dropdown({
    show_line = false,
  }))
end

return {
  -- super powerful fuzzy-finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>p", find_files_or_git_files, mode = "n", desc = "Find Files or Git Files" },
      { "<leader>ff", find_files, mode = "n", desc = "Find Files" },
      -- { "<C-f>", live_grep, mode = "n", desc = "Live Grep (Args)" },
      -- { "<C-f>", grep_string, mode = "v", desc = "Grep String" },
      -- { "<leader>fh", help_tags, mode = "n", desc = "Help Pages" },
      { "<leader>fe", "<cmd>Telescope diagnostics<cr>", mode = "n", desc = "Diagnostics" },
      { "<leader>fn", edit_neovim, mode = "n", desc = "Edit Neovim" },
      { "<leader>hi", highlights, mode = "n", desc = "Neovim Highlight Groups" },
      { "<leader>/", current_buffer_fuzzy_find, mode = "n", desc = "Fuzzy Find in Current Buffer" },
      { "gd", lsp_definitions, mode = "n", desc = "LSP Find Definitions" },
      { "gr", lsp_references, mode = "n", desc = "LSP Find References" },
      { "gi", lsp_implementations, mode = "n", desc = "LSP Find Implementations" },
      { "<leader>u", "<cmd>Telescope undo<cr>", mode = "n", desc = "Undo Tree" },
      -- { "<C-t>", "<cmd>Telescope resume<cr>", mode = "n", desc = "Resume Last List" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          buffer_previewer_maker = new_maker,
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              ["<c-j>"] = require("telescope.actions").move_selection_next,
              ["<c-k>"] = require("telescope.actions").move_selection_previous,
              ["<c-s>"] = require("telescope.actions").select_vertical,
              ["<c-x>"] = require("telescope.actions").select_horizontal,
              ["<c-h>"] = { "<c-s-w>", type = "command" }, -- using Ctrl+Backspace delete a word
              ["<c-bs>"] = { "<c-s-w>", type = "command" }, -- using Ctrl+Backspace delete a word
              ["<C-u>"] = function(prompt_bufnr)
                for _ = 1, 10 do
                  require("telescope.actions").move_selection_previous(prompt_bufnr)
                end
              end,
              ["<C-d>"] = function(prompt_bufnr)
                for _ = 1, 10 do
                  require("telescope.actions").move_selection_next(prompt_bufnr)
                end
              end,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case", the default case_mode is "smart_case"
          },
          undo = {
            mappings = {
              i = {
                -- ["<cr>"] = require("telescope-undo.actions").yank_additions,
                -- ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
                -- ["<C-cr>"] = require("telescope-undo.actions").restore,
                ["<cr>"] = require("telescope-undo.actions").restore,
              },
            },
          },
        },
      })

      require("telescope").load_extension("fzf")
      require("telescope").load_extension("undo")
    end,
  },

  -- native telescope sorter to significantly improve sorting performance
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    lazy = true,
    build = "make",
  },

  -- enable passing arguments to the live_grep of telescope
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    lazy = true,
  },

  -- A telescope extension to view and search your undo tree
  {
    "debugloop/telescope-undo.nvim",
    lazy = true,
  },

  -- Getting you where you want with the fewest keystrokes
  {
    "ThePrimeagen/harpoon",
    keys = {
      {
        "<C-e>",
        function() require("harpoon.ui").toggle_quick_menu() end,
        mode = "n",
        desc = "Harpoon Menu",
      },
      {
        "<leader>a",
        function() require("harpoon.mark").add_file() end,
        mode = "n",
        desc = "Harpoon Add File",
      },
      {
        "<C-j>",
        function() require("harpoon.ui").nav_file(1) end,
        mode = "n",
        desc = "Harpoon Nav File 1",
      },
      {
        "<C-k>",
        function() require("harpoon.ui").nav_file(2) end,
        mode = "n",
        desc = "Harpoon Nav File 2",
      },
      {
        "<C-l>",
        function() require("harpoon.ui").nav_file(3) end,
        mode = "n",
        desc = "Harpoon Nav File 3",
      },
      {
        "<C-h>",
        function() require("harpoon.ui").nav_file(4) end,
        mode = "n",
        desc = "Harpoon Nav File 4",
      },
    },
    config = function()
      vim.api.nvim_create_autocmd({ "Filetype" }, {
        pattern = "harpoon",
        callback = function()
          vim.opt.cursorline = true
          vim.api.nvim_set_hl(0, "HarpoonWindow", { link = "Normal" })
          vim.api.nvim_set_hl(0, "HarpoonBorder", { link = "Normal" })
        end,
      })
    end,
  },
}
