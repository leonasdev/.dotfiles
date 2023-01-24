local status, cmp = pcall(require, "cmp")
if (not status) then
  return
end

local status2, lspkind = pcall(require, "lspkind")
if (not status2) then
  return
end

local status3, luasnip = pcall(require, "luasnip")
if (not status3) then
  return
end

-- reference: https://code.visualstudio.com/docs/editor/intellisense#_types-of-completions
lspkind.init({
  symbol_map = {
    Text = '',
    Method = '',
    Function = '',
    Constructor = '',
    Field = '',
    Variable = '',
    Class = '',
    Interface = '',
    Module = '',
    Property = '',
    Unit = '',
    Value = '',
    Enum = '',
    Keyword = '',
    Snippet = '',
    Color = '',
    File = '',
    Reference = '',
    Folder = '',
    EnumMember = '',
    Constant = '',
    Struct = '',
    Event = '',
    Operator = '',
    TypeParameter = '',
  }
})

require("luasnip.loaders.from_vscode").lazy_load()

luasnip.config.set_config({
  region_check_events = 'CursorMoved'
})

vim.opt.completeopt = "menu,menuone,noselect"

local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

-- nvim-cmp setups
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-k>'] = cmp.mapping.select_prev_item(),
    ['<C-j>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-Space>'] = cmp.mapping.complete(), -- show completion suggestions. <C-Space> not work in windows terminal
    ['<C-e>'] = cmp.mapping.abort(), -- close completion window
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.confirm({
                behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
                select = true -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            })
        elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
        -- elseif has_words_before() then
        --     cmp.complete()
        else
            fallback()
        end
        end, { "i", "s" }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.confirm({
                behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
                select = true -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            })
        elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
        else
            fallback()
        end
        end, { "i", "s" }),
    -- ['<Tab>'] = cmp.mapping.confirm({
    --   behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
    --   select = true -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    -- }),
  }),
  sources = cmp.config.sources({
    -- ordering is matter
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'buffer', keyword_length = 5 }, -- show buffer's completion only if type more then keyword_length
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
      mode = 'symbol_text', -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      menu = ({ -- showing type in menu
        nvim_lsp = "(LSP)",
        path = "(Path)",
        buffer = "(Buffer)",
        luasnip = "(LuaSnip)",
      }),
      before = function(entry, vim_item) -- for tailwind css autocomplete
        if vim_item.kind == 'Color' and entry.completion_item.documentation then
          local _, _, r, g, b = string.find(entry.completion_item.documentation, '^rgb%((%d+), (%d+), (%d+)')
          if r then
            local color = string.format('%02x', r) .. string.format('%02x', g) ..string.format('%02x', b)
            local group = 'Tw_' .. color
            if vim.fn.hlID(group) < 1 then
              vim.api.nvim_set_hl(0, group, {fg = '#' .. color})
            end
            vim_item.kind = "⬤" -- or "■" or anything
            vim_item.kind_hl_group = group
            return vim_item
          end
        end
        -- vim_item.kind = icons[vim_item.kind] and (icons[vim_item.kind] .. vim_item.kind) or vim_item.kind
        -- or just show the icon
        vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
        return vim_item
      end
    })
  }
})

cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})
