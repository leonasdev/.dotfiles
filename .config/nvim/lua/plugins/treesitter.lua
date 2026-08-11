return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      -- Neovim bundles parsers for these, so `language.add()` below succeeds and
      -- the install path never runs -- but the bundled runtime ships no
      -- indents.scm, leaving treesitter indentation silently off for them. Pull
      -- nvim-treesitter's copies once so they behave like every other language.
      local bundled = { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
      local installed = {} ---@type table<string, true>
      for _, lang in ipairs(ts.get_installed()) do
        installed[lang] = true
      end
      local missing = vim.tbl_filter(function(lang) return not installed[lang] end, bundled)
      if #missing > 0 then
        pcall(ts.install, missing)
      end

      local available ---@type table<string, true>?
      local tried = {} ---@type table<string, true>

      ---@param buf integer
      ---@param lang string
      local function attach(buf, lang)
        pcall(vim.treesitter.start, buf, lang)

        if vim.api.nvim_get_runtime_file("queries/" .. lang .. "/indents.scm", true)[1] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      ---Replaces `auto_install` from the master branch: install on first use.
      ---@param lang string
      ---@param on_done fun()
      local function install(lang, on_done)
        if tried[lang] then
          return
        end
        tried[lang] = true

        if not available then
          available = {}
          for _, l in ipairs(ts.get_available()) do
            available[l] = true
          end
        end
        if not available[lang] then
          return
        end

        -- `install()` returns an async Task. Only `:wait()` is documented, but it
        -- blocks the UI while compiling; `:await()` is internal, so degrade to
        -- "installed, just not attached until next time" if upstream drops it.
        local ok, task = pcall(ts.install, lang)
        if not ok then
          return
        end

        pcall(function()
          task:await(function(err)
            if not err then
              vim.schedule(on_done)
            end
          end)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf = args.buf
          local ft = vim.bo[buf].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft

          if vim.treesitter.language.add(lang) then
            attach(buf, lang)
            return
          end

          install(lang, function()
            if not vim.treesitter.language.add(lang) then
              return
            end

            -- Attach every buffer of this filetype, not just the one that
            -- triggered the install -- others may have opened while compiling.
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == ft then
                attach(b, lang)
              end
            end
          end)
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "LazyFile" },
    opts = function()
      local ret = {
        enable = false,
        max_lines = 0,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = "outer",
        mode = "cursor",
        separator = nil,
        zindex = 20,
        on_attach = nil,
      }
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true })
      local tsc = require("treesitter-context")
      Snacks.toggle({
        name = "Treesitter Context",
        get = tsc.enabled,
        set = function(state)
          if state then
            tsc.enable()
          else
            tsc.disable()
          end
        end,
      }):map("<leader>tc")
      return ret
    end,
  },
}
