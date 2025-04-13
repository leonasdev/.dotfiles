-- Deprecated plugins, disabled by default
return {
  { -- suppressed by blink.cmp
    "hrsh7th/nvim-cmp",
    enabled = false,
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
            preset = "codicons",
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

      local format_for_tailwindcss = function(entry, vim_item)
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
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions. <C-Space> not work in windows terminal
          ["<C-e>"] = cmp.mapping.abort(), -- close completion window
          ["<C-y>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
            select = true, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          }),
          -- ["<Tab>"] = cmp.mapping(function(fallback)
          --   if cmp.visible() then
          --     cmp.confirm({
          --       behavior = cmp.ConfirmBehavior.Replace, -- e.g. console.log -> console.inlog -> console.info
          --       select = true, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          --     })
          --   elseif luasnip.expand_or_jumpable() then
          --     luasnip.expand_or_jump()
          --   else
          --     fallback()
          --   end
          -- end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          -- ordering is matter
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer", keyword_length = 5 }, -- show buffer's completion only if type more then keyword_length
          { name = "lazydev", group_index = 0 }, -- set group index to 0 to skip loading LuaLS completions
        }),
        window = {
          completion = cmp.config.window.bordered({
            col_offset = -3, -- align the abbr and word on cursor (due to fields order below)
            side_padding = 0,
          }),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          expandable_indicator = true,
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
              vim_item = format_for_tailwindcss(entry, vim_item) -- for tailwind css autocomplete
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
        }),
        sources = {
          { name = "buffer" },
        },
        formatting = {
          expandable_indicator = true,
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
          expandable_indicator = true,
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
  { -- suppressed by lualine's lsp_status
    "j-hui/fidget.nvim",
    enabled = false, -- suppressed by lualine's lsp_status
    event = "LspAttach",
    config = function()
      require("fidget").setup({
        -- text = {
        --   spinner = "meter",
        -- },
        -- window = {
        --   blend = 0, -- set 0 if using transparent background, otherwise set 100
        -- },
        progress = {
          poll_rate = 200,
          ignore_done_already = true,
          display = {
            done_ttl = 0.5,
            -- done_icon = " ",
            -- Icon shown when LSP progress tasks are in progress
            progress_icon = { pattern = "meter", period = 1 },
            -- Highlight group for in-progress LSP tasks
            progress_style = "WarningMsg",
            group_style = "WarningMsg", -- Highlight group for group name (LSP server name)
            icon_style = "WarningMsg", -- Highlight group for group icons
            done_style = "Conditional", -- Highlight group for completed LSP tasks
          },
        },
        notification = {
          -- override_vim_notify = true,
          window = {
            winblend = 0,
          },
        },
      })
    end,
  },
  { -- suppressed by snacks.picker
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    enabled = false,
    dependencies = {
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
    },
    keys = function()
      local MAX_RESULT = 2000

      local function edit_neovim()
        local opts = {
          prompt_title = "~ Neovim Config ~",
          cwd = vim.fn.stdpath("config"),
          previewer = false,
        }

        require("telescope.builtin").find_files(opts)
      end

      local function find_files_or_git_files()
        if vim.loop.fs_stat(vim.loop.cwd() .. "/.git") then
          local opts = {
            previewer = false,
            show_untracked = false,
            recurse_submodules = true,
            temp__scrolling_limit = MAX_RESULT,
          }

          require("telescope.builtin").git_files(opts)
        else
          local opts = {
            previewer = false,
            no_ignore = true, -- set false to ignore files by .gitignore
            hidden = true, -- set false to ignore dotfiles
            temp__scrolling_limit = MAX_RESULT,
          }

          require("telescope.builtin").find_files(opts)
        end
      end

      local function find_files()
        local opts = {
          previewer = false,
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
        { "<c-p>", find_files_or_git_files, mode = "n", desc = "Find Files or Git Files" },
        { "<leader>ff", find_files, mode = "n", desc = "Find Files" },
        { "<C-f>", live_grep, mode = "n", desc = "Live Grep (Args)" },
        { "<C-f>", grep_string, mode = "v", desc = "Grep String" },
        { "<leader>fh", help_tags, mode = "n", desc = "Help Pages" },
        { "<leader>fe", "<cmd>Telescope diagnostics<cr>", mode = "n", desc = "Diagnostics" },
        { "<leader>fn", edit_neovim, mode = "n", desc = "Edit Neovim" },
        { "<leader>hi", highlights, mode = "n", desc = "Neovim Highlight Groups" },
        { "<leader>/", current_buffer_fuzzy_find, mode = "n", desc = "Fuzzy Find in Current Buffer" },
        { "gd", lsp_definitions, mode = "n", desc = "LSP Find Definitions" },
        { "gr", lsp_references, mode = "n", desc = "LSP Find References" },
        { "gi", lsp_implementations, mode = "n", desc = "LSP Find Implementations" },
        { "<leader>u", "<cmd>Telescope undo<cr>", mode = "n", desc = "Undo Tree" },
        { "<C-t>", "<cmd>Telescope resume<cr>", mode = "n", desc = "Resume Last List" },
      }
    end,
    config = function()
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
  { -- not using anymore
    "ThePrimeagen/harpoon",
    enabled = false,
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
  { -- suppressed by snacks.explorer
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<C-v>", "<cmd>Neotree toggle<cr>", mode = "n", desc = "Toggle Neotree" },
    },
    config = function()
      ---@diagnostic disable: missing-fields
      require("neo-tree").setup({
        close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
        filesystem = {
          follow_current_file = {
            enabled = true,
          },
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
            hide_by_name = {
              ".git",
            },
          },
        },
      })
    end,
  },
  { -- suppressed by snacks.dashboard
    "goolord/alpha-nvim",
    enabled = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local dashboard = require("alpha.themes.dashboard")
      local util = require("util")
      local icons = require("util.icons")

      local version = "v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
      dashboard.section.header.val = "NVIM " .. version

      local userName = "Leon"
      local greeting = util.get_greeting(userName)

      local greetHeading = {
        type = "text",
        val = greeting,
        opts = {
          position = "center",
          hl = "String",
        },
      }

      dashboard.section.buttons.val = {
        util.button("n", icons.dashboard.new .. " New file", "<cmd> enew <cr>"),
        util.button("ctrl + p", icons.dashboard.search .. " Find file", "<cmd> Telescope find_files <cr>"),
        util.button("q", icons.dashboard.quit .. " Quit", "<cmd> qa <cr>"),
      }

      dashboard.config.layout = {
        { type = "padding", val = vim.fn.max({ 2, vim.fn.floor(vim.fn.winheight(0) * 0.35) }) },
        dashboard.section.header,
        { type = "padding", val = 1 },
        greetHeading,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 1 },
        dashboard.section.footer,
        { type = "padding", val = 100 },
      }

      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"

      require("alpha").setup(dashboard.config)

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        desc = "Add load plugins greeting to Alpha dashboad",
        once = true,
        callback = function()
          local stats = require("lazy").stats()
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          dashboard.section.footer.val =
            { "Neovim loaded " .. icons.dashboard.plugins .. stats.count .. " plugins in " .. ms .. "ms" }
          pcall(vim.cmd.AlphaRedraw)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        desc = "Prevent from first ctrl-o not work when enter nvim",
        once = true,
        callback = function()
          local jump_back_key = vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
          vim.api.nvim_feedkeys(jump_back_key, "n", false)
        end,
      })
    end,
  },
}
