return {
  -- Distraction-free coding for Neovim
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<C-w>m", "<CMD>ZenMode<CR>", mode = "n" },
    },
    cmd = "ZenMode",
    config = function() vim.api.nvim_set_hl(0, "ZenBg", { ctermbg = 0 }) end,
  },

  -- commenting
  {
    "numToStr/Comment.nvim",
    config = function() require("Comment").setup() end,
  },

  -- folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      vim.o.foldcolumn = "0" -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

      -- Adding number suffix of folded lines instead of the default ellipsis
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = ("  %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
            print(vim.inspect(chunk))
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end

      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype) return { "treesitter", "indent" } end,
        fold_virt_text_handler = handler,
        open_fold_hl_timeout = 200,
      })
    end,
  },

  -- auto detect indent
  {
    "nmac427/guess-indent.nvim",
    config = function() require("guess-indent").setup() end,
  },

  -- git wrapper
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    config = function() end,
  },

  -- displays a popup with possible keybindings of the command
  {
    "folke/which-key.nvim",
    dependencies = {
      "echasnovski/mini.icons",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      vim.o.timeout = true
      vim.timeoutlen = 300
      require("which-key").setup({
        preset = "modern",
        plugins = {
          presets = {
            g = false,
          },
        },
        win = {
          border = "rounded",
        },
        triggers = { "<auto>", mode = "nso" }, -- disable trigger on visual mode (mode="x")
      })
    end,
  },

  -- lua library for neovim
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- Neovim file explorer: edit your filesystem like a buffer
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "<C-n>", "<CMD>Oil --float<CR>", mode = "n", desc = "Open parent directory" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function discard_and_close()
        require("oil").discard_all_changes()
        require("oil.actions").close.callback()
      end
      require("oil").setup({
        default_file_explorer = true,
        columns = {
          "icon",
        },
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 2,
          max_width = 78,
          max_height = 14,
        },
        keymaps = {
          ["<esc>"] = discard_and_close,
          ["<c-n>"] = discard_and_close,
        },
      })
    end,
  },
}
