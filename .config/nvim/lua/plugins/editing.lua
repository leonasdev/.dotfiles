return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      { "onsails/lspkind-nvim", opts = { preset = "codicons" } },
    },
    version = "1.*",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      completion = {
        accept = { auto_brackets = { enabled = false } },
        -- keyword = { range = "full" }, -- keyword match against the text before and after the cursor

        list = { selection = { preselect = true } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 0,
          window = { border = "rounded" },
        },
        menu = {
          border = "rounded",
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
            components = {
              kind = {
                ellipsis = false,
                width = { fill = true },
                text = function(ctx)
                  if ctx.item.source_id == "cmdline" then
                    return ""
                  end

                  return "(" .. ctx.kind .. ")"
                end,
                highlight = function(_) return "BlinkCmpLabel" end,
              },
              kind_icon = {
                text = function(ctx)
                  if ctx.item.source_id == "cmdline" then
                    return " "
                  end

                  -- use codicons for kind_icon
                  local lspkind = require("lspkind")
                  local icon = ctx.kind_icon
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      icon = dev_icon
                    end
                  else
                    icon = lspkind.symbolic(ctx.kind, { mode = "symbol" })
                  end
                  return icon
                end,
                highlight = function(ctx)
                  -- highlight filetype icons
                  local hl = ctx.kind_hl
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      hl = dev_hl
                    end
                  end
                  return hl
                end,
              },
            },
          },
        },
      },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
    },
    opts_extend = { "sources.default" },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    enabled = false,
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<Down>",
          accept_line = "<Right>",
          next = "<M-j>",
          prev = "<M-k>",
        },
      },
      filetypes = {
        gitcommit = true,
        gitrebase = true,
        yaml = true,
        oil = false,
      },
    },
  },
  {
    "numToStr/Comment.nvim",
    event = "LazyFile",
    opts = {},
  },

  {
    "nmac427/guess-indent.nvim",
    event = "LazyFile",
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    event = "LazyFile",
    opts = {
      keymaps = {
        normal = "s",
        normal_cur = "ss",
        visual = "s",
      },
    },
  },
}
