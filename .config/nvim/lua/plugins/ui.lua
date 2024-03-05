return {
  -- nerd font supported icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "AndreM222/copilot-lualine" },
    config = function()
      local mode_width = 0
      local branch_width = 0
      local diff_width = 0
      local filetype_width = 0
      local filename_width = 0
      require("lualine").setup({
        options = {
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "alpha" },
            winbar = {},
          },
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          refresh = {
            statusline = 500,
          },
        },
        sections = {
          lualine_a = {
            {
              "mode",
              fmt = function(str)
                if str == "" then
                  mode_width = 0
                  return ""
                end
                mode_width = #str + 2 -- 2 is the length of padding
                return str
              end,
            },
          },
          lualine_b = {
            -- { "branch", icon = "" },
            {
              "branch",
              icon = "",
              fmt = function(str)
                if str == "" then
                  branch_width = 0
                  return ""
                end
                branch_width = #str + 2 + 2 -- 4 is the length of icon (unicode), 2 is the length of padding
                return str
              end,
            },
            -- { "diff", colored = true, symbols = { added = " ", modified = " ", removed = " " } },
            {
              "diff",
              fmt = function(str)
                if str == "" then
                  diff_width = 0
                  return ""
                end
                local evaled_str = vim.api.nvim_eval_statusline(str, {}).str
                diff_width = #evaled_str + 2 -- 2 is the length of padding
                return str
              end,
            },
          },
          lualine_c = {
            {
              -- fill space to center the filetype + filename
              function()
                local used_space = mode_width + branch_width + diff_width
                local win_width = vim.opt.columns:get()
                local fill_space =
                  string.rep(" ", math.floor((win_width - filename_width - filetype_width) / 2) - used_space)
                return fill_space
              end,
              padding = { left = 0, right = 0 },
            },
            {
              "filetype",
              fmt = function(str)
                if str == "" then
                  filetype_width = 0
                  return ""
                end
                filetype_width = 1 + 2 -- 4 is the length of icon (unicode), 2 is the length of padding
                return str
              end,
              icon_only = true,
            },
            {
              "filename",
              fmt = function(str)
                if str == "" then
                  filename_width = 0
                  return ""
                end

                local used_space = mode_width + branch_width + diff_width
                local win_width = vim.opt.columns:get()
                local free_space = (math.floor(win_width / 2) - used_space) * 2

                -- if the filename is longer than the free space, use the filename
                if free_space < #str + filetype_width + 10 then
                  str = vim.fn.expand("%:t")
                end

                filename_width = #str + 2 -- 2 is the length of padding

                return str
              end,
              file_status = true, -- Displays file status (readonly status, modified status)
              newfile_status = false, -- Display new file status (new file means no write after created)
              path = 1, -- 0: Just the filename
              -- 1: Relative path
              -- 2: Absolute path
              -- 3: Absolute path, with tilde as the home directory
              -- 4: Filename and parent dir, with tilde as the home directory

              shorting_target = 0, -- Shortens path to leave 40 spaces in the window for other components. (terrible name, any suggestions?)

              symbols = {
                modified = "[+]", -- Text to show when the file is modified.
                readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
                unnamed = "[No Name]", -- Text to show for unnamed buffers.
                newfile = "[New]", -- Text to show for newly created file before first write
              },
            },
          },
          lualine_x = {
            -- {
            --   git_blame.get_current_blame_text,
            --   cond = git_blame.is_blame_text_available,
            -- },
            -- "encoding",
            -- {
            --   function()
            --     return " "
            --   end,
            --   cond = function()
            --     return next(vim.lsp.get_active_clients()) ~= nil
            --   end,
            -- },
            {
              "diagnostics",
              -- padding = { left = 0, right = 1 },
            },
            -- {
            --   "bo:filetype",
            --   padding = { left = 0, right = 1 },
            -- },
            -- "fileformat",
            -- "filetype",
            {
              "copilot",
              show_colors = false,
              symbols = {
                status = {
                  icons = {
                    enabled = " ",
                    sleep = " ", -- auto-trigger disabled
                    disabled = " ",
                    warning = " ",
                    -- unknown = " ",
                    unknown = "",
                  },
                },
              },
              show_loading = false,
            },
            {
              function()
                local autoformat = require("plugins.formatting.autoformat").autoformat
                return autoformat and "󰚔 on" or "󰚔 off"
              end,
            },
          },
          lualine_y = {
            -- "progress",
            {
              "encoding",
              cond = function()
                return vim.opt.columns:get() > 80
              end,
            },
            -- {
            --   function()
            --     local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
            --     return enc:lower() .. "[" .. vim.bo.fileformat:lower() .. "]"
            --   end,
            -- },
          },
          lualine_z = {
            {
              "location",
              padding = { left = 1, right = 0 },
            },
            -- {
            --   function()
            --     local line = vim.fn.line(".")
            --     local column = vim.fn.col(".")
            --     local total_line = vim.fn.line("$")
            --     return string.format("%d/%d :%d", line, total_line, column)
            --   end,
            --   padding = { left = 0, right = 1 },
            -- },
            -- {
            --   function()
            --     local line = vim.fn.line(".")
            --     local column = vim.fn.col(".")
            --     return string.format("%d,%d", line, column)
            --   end,
            -- },
            "progress",
          },
        },
        extensions = {
          "neo-tree",
          "nvim-dap-ui",
        },
      })

      vim.opt.showmode = false
    end,
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufEnter",
    config = function()
      require("colorizer").setup({
        filetypes = { "*" },
        user_default_options = {
          names = false,
          tailwind = "both",
          mode = "background",
        },
      })
    end,
  },

  -- git decorations
  {
    "lewis6991/gitsigns.nvim",
    event = "BufEnter",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
        },
        current_line_blame = false,
        current_line_blame_opts = {
          delay = 200,
        },
        -- signs = {
        --   add = { text = '+' },
        --   change = { text = '~' },
        --   delete = { text = '_' },
        --   topdelete = { text = '‾' },
        --   changedelete = { text = '~' },
        -- },
      })
    end,
  },

  -- Standalone UI for nvim-lsp progress
  {
    "j-hui/fidget.nvim",
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

  -- Neovim plugin to improve the default vim.ui interfaces
  {
    "stevearc/dressing.nvim",
    event = "BufEnter",
    config = function()
      require("dressing").setup({
        input = {
          win_options = {
            winblend = 0,
          },
        },
      })
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<C-b>", "<cmd>Neotree toggle<cr>", mode = "n", desc = "Toggle Neotree" },
    },
    config = function()
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

  {
    "lukas-reineke/indent-blankline.nvim",
    version = "2",
    config = function()
      vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "IndentBlanklineChar" })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "IndentBlanklineChar" })
        end,
        group = vim.api.nvim_create_augroup("RelinkIndentBlanklineHightLightGroup", { clear = true }),
        desc = "Relink IndentBlankline Highlight Group",
      })
      require("indent_blankline").setup({
        char = "",
        context_char = "│",
        show_current_context = true,
      })
    end,
  },

  {
    "luukvbaal/statuscol.nvim",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        ft_ignore = { "alpha", "neo-tree", "oil" },
        segments = {
          { sign = { name = { "Diagnostic" } } },
          { sign = { name = { "Dap.*" } } },
          { text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
          { sign = { namespace = { "gitsign" }, auto = false } },
        },
      })
    end,
  },

  {
    "echasnovski/mini.animate",
    version = false,
    cmd = "CoworkingToggle",
    config = function()
      local isCoworking = false
      local animate = require("mini.animate")
      local Util = require("lazy.core.util")

      local coworking_setup = function()
        if isCoworking then
          animate.setup({
            cursor = { enable = false },
            scroll = {
              enable = true,
              timing = animate.gen_timing.cubic({ duration = 50, unit = "total" }),
            },
            resize = { enable = false },
            open = { enable = false },
            close = { enable = false },
          })

          vim.keymap.set("n", "<C-d>", "<C-d>")
          vim.keymap.set("n", "<C-u>", "<C-u>")

          vim.opt.relativenumber = false
          vim.opt.number = true
        else
          animate.setup({
            cursor = { enable = false },
            scroll = { enable = false },
            resize = { enable = false },
            open = { enable = false },
            close = { enable = false },
          })

          vim.keymap.set("n", "<C-d>", "<C-d>zz")
          vim.keymap.set("n", "<C-u>", "<C-u>zz")

          vim.opt.relativenumber = true
          vim.opt.number = true
        end
      end

      vim.api.nvim_create_user_command("CoworkingToggle", function()
        isCoworking = not isCoworking
        if isCoworking then
          Util.warn("Enabled coworking mode", { title = "Coworking" })
        else
          Util.info("Disabled coworking mode", { title = "Coworking" })
        end
        coworking_setup()
      end, { desc = "Toggle coworking mode (add scrolling animation)" })

      coworking_setup()
    end,
  },

  -- a lua powered greeter like vim-startify / dashboard-nvim
  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local util = require("util")
      local dashboard = require("alpha.themes.dashboard")

      -- local logo = {
      --   [[0    0    0    0    0    0]],
      --   [[1    1    1    1    1    1]],
      --   [[1    1    1    1    1    1]],
      --   [[0    0    0    1    0    0]],
      --   [[1    0    1    0    1    1]],
      --   [[1    1    1    1    0    1]],
      --   [[1    0    1    1    0    0]],
      --   [[0    1    1    0    1    1]],
      -- }
      --
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
        util.button("n", " " .. " New file", "<cmd> enew <cr>"),
        util.button("ctrl + p", " " .. " Find file", "<cmd> Telescope find_files <cr>"),
        util.button("q", " " .. " Quit", "<cmd> qa <cr>"),
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
          dashboard.section.footer.val = { "Neovim loaded  " .. stats.count .. " plugins in " .. ms .. "ms" }
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
