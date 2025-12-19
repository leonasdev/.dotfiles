return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "AndreM222/copilot-lualine" },
    opts = {
      options = {
        globalstatus = true,
        disabled_filetypes = {
          statusline = { "alpha", "snacks_dashboard" },
        },
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = require("util.statusline").sections,
      extensions = {
        "neo-tree",
        "nvim-dap-ui",
      },
    },
    config = function(_, opts)
      require("lualine").setup(opts)
      vim.opt.showmode = false
    end,
  },
  { -- TODO: do not use v2 anymore
    "lukas-reineke/indent-blankline.nvim",
    event = "LazyFile",
    version = "2",
    opts = {
      char = "",
      context_char = "│",
      show_current_context = true,
    },
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "IndentBlanklineChar" })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function() vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { link = "IndentBlanklineChar" }) end,
        group = vim.api.nvim_create_augroup("RelinkIndentBlanklineHightLightGroup", { clear = true }),
        desc = "Relink IndentBlankline Highlight Group",
      })
      local ft_excludes = vim.g.indent_blankline_filetype_exclude
      table.insert(ft_excludes, "snacks_picker_preview")
      vim.g.indent_blankline_filetype_exclude = ft_excludes
      require("indent_blankline").setup(opts)
    end,
  },
  { -- TODO: try snacks.statuscolumn
    "luukvbaal/statuscol.nvim",
    event = "VeryLazy",
    opts = function()
      local builtin = require("statuscol.builtin")
      local util = require("util")

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

      return {
        relculright = true, -- whether to right-align the cursor line number with 'relativenumber' set
        ft_ignore = { "alpha", "neo-tree", "oil", "snacks_dashboard" },
        segments = {
          { sign = { namespace = { "diagnostic" } } },
          { sign = { name = { "Dap.*" } }, click = "v:lua.ScLa" },
          { -- line number
            text = {
              -- TODO: turn into absolute line number when in visual mode

              -- highlight the line number of selection in virtual mode
              function(args)
                local v_hl = ""
                ---@diagnostic disable: undefined-field
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
      }
    end,
  },
  { -- TODO: deprecate this
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    keys = {
      { "zo" },
      { "zO" },
      { "zc" },
      { "zC" },
      { "za" },
      { "zA" },
      { "zx" },
      { "zX" },
      { "zm" },
      { "zM" },
      { "zr" },
      { "zR" },
    },
    -- event = "LazyFile",
    opts = function()
      return {
        provider_selector = function() return { "treesitter", "indent" } end,
        -- Adding number suffix of folded lines instead of the default ellipsis
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = ("  %d "):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2]
              table.insert(newVirtText, { chunkText, hlGroup })
              chunkWidth = vim.fn.strdisplaywidth(chunkText)
              -- str width returned from truncate() may less than 2nd argument, need padding
              if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
              end
              break
            end
            curWidth = curWidth + chunkWidth
          end
          table.insert(newVirtText, { suffix, "MoreMsg" })
          return newVirtText
        end,
        open_fold_hl_timeout = 200,
      }
    end,
    config = function(_, opts)
      vim.o.foldcolumn = "0" -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
      require("ufo").setup(opts)
    end,
  },
  {
    "folke/which-key.nvim",
    dependencies = {
      "echasnovski/mini.icons",
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    keys = {
      {
        "<leader>?",
        function() require("which-key").show() end,
        desc = "Show keymaps",
      },
    },
    opts = {
      preset = "helix",
      plugins = { presets = { g = false } },
      win = { border = "rounded" },
      triggers = { "<auto>", mode = "nso" }, -- disable trigger on visual mode (mode="x")
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>m", function() Snacks.notifier.show_history() end, mode = "n", desc = "Show Notification History" },
    },
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        desc = "Prevent from first ctrl-o not work when enter nvim",
        once = true,
        callback = function() vim.keymap.set("n", "<C-o>", "2<C-o>", { buffer = true, silent = true }) end,
      })

      ---@type snacks.Config
      local ret = {
        dashboard = {
          enabled = true,
          width = 30,
          preset = {
            keys = {
              { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
              { icon = "󰱼 ", key = "<ctrl-p>", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
              { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
          },
          sections = {
            { -- nvim version
              text = {
                {
                  string.format("NVIM v%s.%s.%s", vim.version().major, vim.version().minor, vim.version().patch),
                  hl = "SnacksDashboardHeader",
                },
              },
              align = "center",
              padding = 1,
            },
            { -- greeting
              text = {
                {
                  require("util").get_greeting("Leon"),
                  hl = "String",
                },
              },
              align = "center",
              padding = 2,
            },
            { section = "keys", gap = 1, padding = 2 },
            {
              function()
                local startup = Snacks.dashboard.sections.startup({ icon = "" })
                if startup then
                  table.insert(startup.text, 2, { " ", hl = "special" })
                end
                return startup
              end,
            },
          },
        },
        words = { enabled = true, modes = { "n" } }, -- highlight references on cursor hold
        -- TODO: figure it out
        toggle = { enabled = true },
        notifier = { -- Better vim.notify
          enabled = true,
          width = { min = 0.2, max = 0.2 },
        },
        input = { enabled = true }, -- Better vim.ui.input
        styles = {
          ---@diagnostic disable: missing-fields
          dashboard = {
            wo = {
              fillchars = "eob: ",
            },
          },
          ---@diagnostic disable: missing-fields
          notification = {
            ft = "markdown",
            wo = {
              wrap = true,
              -- linebreak = false,
              showbreak = "",
            },
          },
          ---@diagnostic disable: missing-fields
          notification_history = {
            minimal = true,
            keys = { ["<esc>"] = "close" },
          },
          input = {
            relative = "cursor",
            row = -3,
            col = 0,
            width = 40,
            keys = {
              i_ctrl_bs = { "<c-bs>", "<c-s-w>", mode = { "i" }, expr = true },
              i_ctrl_h = { "<c-h>", "<c-s-w>", mode = { "i" }, expr = true },
            },
          },
        },
      }
      return vim.tbl_deep_extend("force", opts or {}, ret)
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
              timing = animate.gen_timing.quartic({ duration = 50, unit = "total" }),
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
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<C-w>m", function() require("zen-mode").toggle() end, mode = "n" },
    },
    cmd = "ZenMode",
    opts = {
      window = {
        backdrop = 1,
        width = 0.95,
      },
    },
  },
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      filetypes = { "*" },
      user_default_options = {
        names = false,
        tailwind = "both",
        mode = "background",
      },
    },
  },
  {
    "nvzone/showkeys",
    cmd = "ShowkeysToggle",
    opts = {
      winopts = {
        border = "rounded",
      },
      maxkeys = 5,
      position = "bottom-right",
    },
  },
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      smear_insert_mode = false,
      --- faster with smear
      stiffness = 1, -- 0.6      [0, 1]
      trailing_stiffness = 0.9, -- 0.45     [0, 1]
      damping = 0.85, -- 0.85     [0, 1]
      distance_stop_animating = 1, -- 0.1      > 0
      time_interval = 5, -- 17
      delay_event_to_smear = 2,
      matrix_pixel_threshold = 0.5,

      --- smooth cursor without smear
      -- stiffness = 1,
      -- trailing_stiffness = 1,
      -- matrix_pixel_threshold = 0.5,
      -- time_interval = 5, -- 17
      -- delay_event_to_smear = 2,
    },
  },
}
