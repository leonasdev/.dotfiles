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

vim.opt.completeopt = "menu,menuone,noselect"

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
    ['<Tab>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
      select = true -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
  }),
  sources = cmp.config.sources({
    -- ordering is matter
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'buffer', keyword_length = 5 }, -- show buffer's completion only if type more then keyword_length
  }),
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text', -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      menu = ({ -- showing type in menu
        nvim_lsp = "[LSP]",
        path = "[Path]",
        buffer = "[Buffer]",
        luasnip = "[LuaSnip]",
      })
    })
  }
})
