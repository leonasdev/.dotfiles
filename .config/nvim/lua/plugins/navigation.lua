return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      {
        "<C-p>",
        function()
          ---@diagnostic disable: undefined-field
          if vim.loop.fs_stat(vim.loop.cwd() .. "/.git") then
            Snacks.picker.git_files()
          else
            Snacks.picker.files()
          end
        end,
        mode = "n",
      },
      { "<leader>ff", function() Snacks.picker.files() end, mode = "n" },
      { "<C-f>", function() Snacks.picker.grep() end, mode = "n" },
      { "<C-t>", function() Snacks.picker.resume() end, mode = "n" },
      {
        "<leader>fn",
        function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = " Neovim Config" }) end,
        mode = "n",
        desc = "Edit Neovim",
      },
      { "<leader>fh", function() Snacks.picker.help() end, mode = "n" },
      { "<leader>cl", function() Snacks.picker.colorschemes() end, mode = "n" },
      { "<leader>hi", function() Snacks.picker.highlights() end, mode = "n" },
      { "<leader>u", function() Snacks.picker.undo() end, mode = "n" },
      { "<C-b>", function() Snacks.explorer.open() end, mode = "n", desc = "Toggle file tree" },
    },
    opts = function()
      ---@type snacks.picker.layout.Config
      local picker_files_layout = {
        ---@diagnostic disable: assign-type-mismatch
        preview = false,
        layout = {
          backdrop = false,
          row = 1,
          width = 0.4,
          min_width = 80,
          height = 0.4,
          border = "rounded",
          box = "vertical",
          title = "{title}",
          { win = "input", height = 2, border = "none" },
          { win = "list", border = "hpad" },
          { win = "preview", title = "{preview}", border = "rounded" },
        },
      }

      ---@type snacks.Config
      local ret = {
        picker = {
          enabled = true,
          ---@diagnostic disable: missing-fields
          icons = {
            diagnostics = {
              Error = require("util.icons").diagnostics.error,
              Warn = require("util.icons").diagnostics.warn,
              Info = require("util.icons").diagnostics.info,
              Hint = require("util.icons").diagnostics.hint,
            },
          },
          win = {
            input = {
              keys = {
                ["<Esc>"] = { "close", mode = { "n", "i" } },
                ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true },
                ["<C-BS>"] = { "<c-s-w>", mode = { "i" }, expr = true },
                ["<c-s>"] = { "edit_vsplit", mode = { "i", "n" } },
                ["<c-x>"] = { "edit_split", mode = { "i", "n" } },
              },
            },
          },
          sources = {
            git_files = { title = "󰱼 Find File (Git)", layout = picker_files_layout, submodules = true },
            files = { title = "󰱼 Find File", layout = picker_files_layout, hidden = true, ignored = true },
            grep = { title = "󰺮 Grep", layout = "ivy_split", hidden = false, ignored = true },
            help = { title = "󱤇 Help", layout = "bottom" },
            colorschemes = {
              title = " Colorschemes",
              layout = "select",
              matcher = {
                sort_empty = true,
              },
              -- current active colorscheme should show on top
              sort = function(a, b)
                local default_sort = require("snacks.picker.sort").default({ fields = { "#text" } })
                local a_is_current = a.text == vim.g.colors_name
                local b_is_current = b.text == vim.g.colors_name

                if a_is_current and not b_is_current then
                  return true
                elseif not a_is_current and b_is_current then
                  return false
                else
                  return default_sort(a, b)
                end
              end,
            },
            lsp_definitions = { layout = "dropdown" },
            lsp_references = { layout = "dropdown" },
            lsp_declarations = { layout = "dropdown" },
            explorer = {
              win = {
                input = {
                  keys = {
                    ["<Esc>"] = { "cancel", mode = { "n" } }, -- prevent <esc> to close explorer on insert mode (by picker.win.input.keys.["<Esc>"])
                  },
                },
                list = {
                  keys = {
                    ["<C-b>"] = { "close", mode = { "n" } },
                    ["o"] = "",
                  },
                },
              },
            },
          },
        },
        explorer = { enabled = true },
      }

      return ret
    end,
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "<c-n>", function() require("oil").open_float() end, mode = "n", desc = "Open file explorer" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local function discard_and_close()
        require("oil").discard_all_changes()
        require("oil.actions").close.callback()
      end
      return {
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
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      vim.list_extend(require("plugins.lsp.keymaps").keys, {
        { "n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Go to Definitions" } },
        { "n", "gr", function() Snacks.picker.lsp_references() end, { desc = "Go to References" } },
        { "n", "gi", function() Snacks.picker.lsp_implementations() end, { desc = "Go to Implementations" } },
      })
    end,
  },
}
