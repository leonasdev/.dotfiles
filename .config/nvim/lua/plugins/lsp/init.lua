local function setup_diagnostic()
  local icons = require("util.icons")
  vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    virtual_text = {
      prefix = icons.diagnostics.virtual_text.prefix,
      severity_sort = true,
    },
    float = {
      border = "rounded",
      source = true, -- Always show the source of diagnostic
      prefix = " - ",
    },
    signs = {
      linehl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticErrorLn",
        [vim.diagnostic.severity.WARN] = "DiagnosticWarnLn",
        [vim.diagnostic.severity.INFO] = "DiagnosticInfoLn",
        [vim.diagnostic.severity.HINT] = "DiagnosticHintLn",
      },
      text = {
        [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
        [vim.diagnostic.severity.WARN] = icons.diagnostics.warn,
        [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
        [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
      },
    },
  })
end

local function setup_lsp()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local opts = { buffer = bufnr }
      if not client then
        return
      end

      vim.keymap.set("n", "<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
      vim.keymap.set("n", "<leader>dp", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
      vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, opts)
      vim.keymap.set({ "i", "n" }, "<C-s>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "gd", function() Snacks.picker.lsp_definitions() end, opts)
      vim.keymap.set("n", "gr", function() Snacks.picker.lsp_references() end, opts)
      vim.keymap.set("n", "gi", function() Snacks.picker.lsp_implementations() end, opts)

      -- auto show diagnostic when cursor hold
      vim.api.nvim_create_autocmd("CursorHold", {
        buffer = bufnr,
        callback = function()
          if not vim.b.diagnostics_pos then
            vim.b.diagnostics_pos = { nil, nil }
          end

          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          -- only open_float when cursor pos changed
          if
            (cursor_pos[1] ~= vim.b.diagnostics_pos[1] or cursor_pos[2] ~= vim.b.diagnostics_pos[2])
            and #vim.diagnostic.get() > 0
          then
            vim.diagnostic.open_float({
              nil,
              close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "InsertCharPre", "FocusLost" },
            })
          end

          vim.b.diagnostics_pos = cursor_pos
        end,
      })
    end,
  })

  local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = vim.tbl_deep_extend(
    "force",
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_cmp and cmp_nvim_lsp.default_capabilities() or {},
    has_blink and blink.get_lsp_capabilities() or {}
  )

  local setup_server = function(server, config)
    if not config then
      return
    end

    if type(config) ~= "table" then
      config = {}
    end

    config = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
    }, config)

    require("lspconfig")[server].setup(config)
  end

  local servers = require("plugins.lsp.langueage_servers")
  for server, setting in pairs(servers) do
    if setting.disabled then
      goto continue
    end

    if setting.config ~= nil then
      setup_server(server, setting.config)
    else
      setup_server(server, {})
    end

    ::continue::
  end
end

return {
  -- configuration for nvim lsp
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {

      -- for develop neovim
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { path = "snacks.nvim", words = { "Snacks" } },
            { path = "lazy.nvim", words = { "LazyVim" } },
          },
        },
      },

      -- managing tool
      { "williamboman/mason.nvim" },

      -- bridges mason with the lspconfig
      { "williamboman/mason-lspconfig.nvim" },
      { "folke/snacks.nvim" },
    },
    config = function()
      setup_diagnostic()
      setup_lsp()
    end,
  },
}
