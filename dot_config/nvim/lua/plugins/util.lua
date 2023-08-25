return {
  -- lua library for neovim
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- Distraction-free coding for Neovim
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    config = function()
      vim.api.nvim_set_hl(0, "ZenBg", { ctermbg = 0 })
    end,
  },

  -- commenting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
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
        provider_selector = function(bufnr, filetype, buftype)
          return { "treesitter", "indent" }
        end,
        fold_virt_text_handler = handler,
        open_fold_hl_timeout = 200,
      })
    end,
  },

  -- auto detect indent
  {
    "nmac427/guess-indent.nvim",
    config = function()
      require("guess-indent").setup()
    end,
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
    config = function()
      vim.o.timeout = true
      vim.timeoutlen = 300
      require("which-key").setup({
        plugins = {
          presets = {
            g = false,
          },
        },
        window = {
          border = "single",
        },
      })
    end,
  },
}
