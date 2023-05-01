return {
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-buffer", -- nvim-cmp source for buffer words
      "hrsh7th/cmp-path", -- nvim-cmp source for path words
      "hrsh7th/cmp-nvim-lsp", -- nvim-cmp source for neovim's built-in LSP
      "saadparwaiz1/cmp_luasnip", -- nvim-cmp source for luasnip
      "hrsh7th/cmp-cmdline", -- nvim-cmp source for vim's cmdline
      -- Snippet engine
      {
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets", -- Set of preconfigured snippets for different languages.
        config = function()
          local luasnip = require("luasnip")

          -- forget the current snippet when leaving the insert mode. ref: https://github.com/L3MON4D3/LuaSnip/issues/656#issuecomment-1313310146
          local unlinkgrp = vim.api.nvim_create_augroup("UnlinkSnippetOnModeChange", { clear = true })

          vim.api.nvim_create_autocmd("ModeChanged", {
            group = unlinkgrp,
            pattern = { "s:n", "i:*" },
            desc = "Forget the current snippet when leaving the insert mode",
            callback = function(evt)
              if luasnip.session and luasnip.session.current_nodes[evt.buf] and not luasnip.session.jump_active then
                luasnip.unlink_current()
              end
            end,
          })

          luasnip.filetype_extend("typescriptreact", { "html", "typescript" })
          luasnip.filetype_extend("javascriptreact", { "html", "javascript" })

          require("luasnip.loaders.from_vscode").lazy_load()
          luasnip.config.set_config({
            region_check_events = "CursorMoved",
          })
        end,
      },

      -- vscode-like pictograms
      {
        "onsails/lspkind-nvim",
        config = function()
          require("lspkind").init({
            symbol_map = {
              Text = "",
              Method = "",
              Function = "",
              Constructor = "",
              Field = "",
              Variable = "",
              Class = "",
              Interface = "",
              Module = "",
              Property = "",
              Unit = "",
              Value = "",
              Enum = "",
              Keyword = "",
              Snippet = "",
              Color = "",
              File = "",
              Reference = "",
              Folder = "",
              EnumMember = "",
              Constant = "",
              Struct = "",
              Event = "",
              Operator = "",
              TypeParameter = "",
            },
          })
        end,
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      vim.opt.completeopt = "menu,menuone,noselect"
      vim.opt.pumheight = 10 -- Maximum number of items to show in the popup menu

      local formatForTailwindCSS = function(entry, vim_item)
        if vim_item.kind == "Color" and entry.completion_item.documentation then
          local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
          if r then
            local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
            local group = "Tw_" .. color
            if vim.fn.hlID(group) < 1 then
              vim.api.nvim_set_hl(0, group, { fg = "#" .. color })
            end
            vim_item.kind = "●" -- or "■" or anything
            vim_item.kind_hl_group = group
            return vim_item
          end
        end
        -- vim_item.kind = icons[vim_item.kind] and (icons[vim_item.kind] .. vim_item.kind) or vim_item.kind
        -- or just show the icon
        vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
        return vim_item
      end

      cmp.setup({
        matching = {
          -- disallow_fuzzy_matching = true,
          -- disallow_fullfuzzy_matching = true,
          -- disallow_partial_fuzzy_matching = true,
          -- disallow_partial_matching = true,
          -- disallow_prefix_unmatching = false,
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions. <C-Space> not work in windows terminal
          ["<C-e>"] = cmp.mapping.abort(), -- close completion window
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({
                behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
                select = true, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
              })
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          -- ordering is matter
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer", keyword_length = 5 }, -- show buffer's completion only if type more then keyword_length
        }),
        window = {
          -- completion = {
          --   col_offset = -3 -- align the abbr and word on cursor (due to fields order below)
          -- },
          -- documentation = {
          --   winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None"
          -- },

          -- border style
          completion = cmp.config.window.bordered({
            col_offset = -3, -- align the abbr and word on cursor (due to fields order below)
            side_padding = 0,
          }),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = lspkind.cmp_format({
            mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            -- menu = ({ -- showing type in menu
            --   nvim_lsp = "(LSP)",
            --   path = "(Path)",
            --   buffer = "(Buffer)",
            --   luasnip = "(LuaSnip)",
            -- }),
            before = function(entry, vim_item)
              vim_item.menu = "(" .. vim_item.kind .. ")"
              vim_item.dup = ({
                nvim_lsp = 0,
                path = 0,
              })[entry.source.name] or 0
              vim_item = formatForTailwindCSS(entry, vim_item) -- for tailwind css autocomplete
              return vim_item
            end,
          }),
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline({
          ["<C-k>"] = cmp.mapping({
            c = function(fallback)
              if cmp.visible() then
                return cmp.select_prev_item()
              end
              fallback()
            end,
          }),
          ["<C-j>"] = cmp.mapping({
            c = function(fallback)
              if cmp.visible() then
                return cmp.select_next_item()
              end
              fallback()
            end,
          }),
          ["<Tab>"] = cmp.mapping({
            c = function(fallback)
              if cmp.visible() then
                return cmp.confirm({
                  behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
                  select = true, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                })
              else
                return fallback()
              end
            end,
          }),
        }),
        sources = {
          { name = "buffer" },
        },
        formatting = {
          fields = { "abbr", "kind" },
          format = lspkind.cmp_format({
            mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            before = function(_, vim_item)
              if vim_item.kind == "Text" then
                vim_item.kind = ""
                return vim_item
              end
              -- just show the icon
              vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
              return vim_item
            end,
          }),
        },
      })

      cmp.setup.cmdline(":", {
        completion = {
          autocomplete = false,
        },
        mapping = cmp.mapping.preset.cmdline({
          ["<C-k>"] = cmp.mapping({
            c = function(fallback)
              if cmp.visible() then
                return cmp.select_prev_item()
              end
              fallback()
            end,
          }),
          ["<C-j>"] = cmp.mapping({
            c = function(fallback)
              if cmp.visible() then
                return cmp.select_next_item()
              end
              fallback()
            end,
          }),
          ["<Tab>"] = cmp.mapping({
            c = function()
              if cmp.visible() then
                return cmp.select_next_item()
              else
                cmp.complete()
                cmp.select_next_item()
                return
              end
            end,
          }),
          ["<S-Tab>"] = cmp.mapping({
            c = function()
              if cmp.visible() then
                return cmp.select_prev_item()
              else
                cmp.complete()
                cmp.select_next_item()
                return
              end
            end,
          }),
        }),
        sources = {
          { name = "path" },
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        },
        formatting = {
          fields = { "abbr", "kind" },
          format = lspkind.cmp_format({
            mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            before = function(_, vim_item)
              if vim_item.kind == "Variable" then
                vim_item.kind = ""
                return vim_item
              end
              -- just show the icon
              vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
              return vim_item
            end,
          }),
        },
      })
    end,
  },
}
