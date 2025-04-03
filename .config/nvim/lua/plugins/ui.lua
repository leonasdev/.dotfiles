local util = require("util")

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
    -- commit = "640260d7c2d98779cab89b1e7088ab14ea354a02", -- i have some issue with latest commit (delay between mode switching)
    config = function()
      require("lualine").setup({
        options = {
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "alpha" },
            winbar = {},
          },
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          -- refresh = {
          --   statusline = 500,
          -- },
        },
        sections = require("util.statusline").sections,
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
    keys = {
      {
        "<leader>tb",
        function() require("gitsigns").toggle_current_line_blame() end,
        desc = "Toggle Current Line Blame",
      },
    },
    event = "BufEnter",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
        },
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = false,
          -- virt_text_pos = "eol", -- or "overlay" "right_align"
          delay = 200,
        },
        -- current_line_blame_formatter = " <author>, <author_time:%R> - <summary>",
        worktrees = {
          {
            toplevel = vim.env.HOME,
            gitdir = vim.env.HOME .. "/.dotfiles",
          },
          {
            toplevel = vim.env.HOME,
            gitdir = vim.env.HOME .. "/personal/.dotfiles",
          },
        },
      })
    end,
  },

  -- Standalone UI for nvim-lsp progress
  {
    "j-hui/fidget.nvim",
    enabled = false,
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
        callback = function() vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "IndentBlanklineChar" }) end,
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

      local function get_num_wraps()
        -- Calculate the actual buffer width, accounting for splits, number columns, and other padding
        local wrapped_lines = vim.api.nvim_win_call(0, function()
          local winid = vim.api.nvim_get_current_win()

          -- get the width of the buffer
          local winwidth = vim.api.nvim_win_get_width(winid)
          local numberwidth = vim.wo.number and vim.wo.numberwidth or 0
          local signwidth = vim.fn.exists("*sign_define") == 1 and vim.fn.sign_getdefined() and 2 or 0
          local foldwidth = vim.wo.foldcolumn or 0

          -- subtract the number of empty spaces in your statuscol. I have
          -- four extra spaces in mine, to enhance readability for me
          local bufferwidth = winwidth - numberwidth - signwidth - foldwidth - 4

          -- fetch the line and calculate its display width
          local line = vim.fn.getline(vim.v.lnum)
          local line_length = vim.fn.strdisplaywidth(line)

          return math.floor(line_length / bufferwidth)
        end)

        return wrapped_lines
      end

      require("statuscol").setup({
        relculright = true, -- whether to right-align the cursor line number with 'relativenumber' set
        ft_ignore = { "alpha", "neo-tree", "oil" },
        segments = {
          { sign = { namespace = { "diagnostic" } } },
          { sign = { name = { "Dap.*" } }, click = "v:lua.ScLa" },
          { -- line number
            text = {
              -- TODO: turn into absolute line number when in visual mode

              -- highlight the line number of selection in virtual mode
              function(args)
                local v_hl = ""
                local mode = vim.fn.strtrans(vim.fn.mode()):lower():gsub("%W", "")
                if mode == "v" then
                  local v_range = util.get_visual_range()
                  local is_in_range = vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3]
                  v_hl = is_in_range and "%#CursorLineNr#" or ""
                end

                if vim.v.virtnum < 0 then
                  return "-"
                elseif vim.v.virtnum > 0 and (vim.wo.number or vim.wo.relativenumber) then
                  local num_wraps = get_num_wraps()

                  if vim.v.virtnum == num_wraps then
                    return v_hl .. "%=" .. "└"
                  else
                    return v_hl .. "%=" .. "├"
                  end
                end

                return v_hl .. builtin.lnumfunc(args)
              end,
            },
            click = "v:lua.ScLa",
          },
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
      local dashboard = require("alpha.themes.dashboard")

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
  {
    "nvzone/showkeys",
    cmd = "ShowkeysToggle",
    config = function()
      require("showkeys").setup({
        position = "bottom-left",
      })
    end,
  },
}
