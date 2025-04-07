local M = {}

local used_spaces_table = {}

--- @class get_used_space.opt
--- @field exclude string[]
--- @param opts get_used_space.opt value to exclude.
local function get_used_space(opts)
  local used_space = 0
  for k, v in pairs(used_spaces_table) do
    if vim.tbl_contains(opts.exclude, k) then
      goto continue
    end
    used_space = used_space + v
    ::continue::
  end
  return used_space
end

local icons = require("util.icons")

local components = {
  mode = {
    "mode",
    fmt = function(str)
      if str == "" then
        used_spaces_table["mode"] = 0
      else
        used_spaces_table["mode"] = #str + 2 -- 2 is the length of padding
      end
      return str
    end,
  },
  branch = {
    "b:gitsigns_head",
    icon = "",
    cond = function()
      local should_show = vim.opt.columns:get() > 60
      if not should_show then
        used_spaces_table["branch"] = 0
      end
      return should_show
    end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["branch"] = 0
      else
        used_spaces_table["branch"] = #str + 2 + 2 -- 4 is the length of icon (unicode), 2 is the length of padding
      end
      return str
    end,
  },
  diff = {
    "diff",
    source = function()
      local gitsigns = vim.b.gitsigns_status_dict
      if gitsigns then
        return {
          added = gitsigns.added,
          modified = gitsigns.changed,
          removed = gitsigns.removed,
        }
      end
    end,
    symbols = {
      added = icons.diff.added,
      modified = icons.diff.modified,
      removed = icons.diff.removed,
    },
    cond = function()
      local should_show = vim.opt.columns:get() > 60
      return should_show
    end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["diff"] = 0
      else
        local evaled_str = vim.api.nvim_eval_statusline(str, {}).str
        used_spaces_table["diff"] = vim.fn.strchars(evaled_str) + 2 -- 2 is the length of padding
      end
      return str
    end,
  },
  fill_space = {
    -- fill space to center the filetype + filename
    function()
      local used_space = used_spaces_table["mode"] + used_spaces_table["branch"] + used_spaces_table["diff"]
      local win_width = vim.opt.columns:get()
      local fill_space = string.rep(
        " ",
        math.floor((win_width - used_spaces_table["filename"] - used_spaces_table["filetype"]) / 2) - used_space
      )
      return fill_space
    end,
    padding = { left = 0, right = 0 },
    cond = function() return vim.opt.columns:get() > 60 end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["fill_space"] = 0
      else
        used_spaces_table["fill_space"] = #str
      end
      return str
    end,
  },
  filetype = {
    "filetype",
    fmt = function(str)
      if str == "" then
        used_spaces_table["filetype"] = 0
      else
        used_spaces_table["filetype"] = 2 + 1 -- 2 is the length of icon (unicode), 1 is the length of padding
      end
      return str
    end,
    icon_only = true,
    padding = { left = 0, right = 1 },
  },
  filename = {
    "filename",
    fmt = function(filename)
      if filename == "" then
        used_spaces_table["filename"] = 0
        return ""
      end
      local free_space = vim.opt.columns:get() - get_used_space({ exclude = { "filetype", "filename", "fill_space" } })
      -- if the filename is longer than the free space, use the filename
      if free_space < #filename + used_spaces_table["filetype"] + 4 then
        filename = vim.fs.basename(filename)
      end
      used_spaces_table["filename"] = #filename + 1 -- 1 is the length of padding
      return filename
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
    padding = { left = 0, right = 1 },
  },
  blame = {
    function()
      local current_blame_line = vim.b.gitsigns_blame_line_dict
      if current_blame_line.author == "Not Committed Yet" then
        return ""
      end

      return "󰜘 "
        .. current_blame_line.author
        .. " ("
        .. require("gitsigns.util").get_relative_time(current_blame_line.author_time)
        .. ")"
    end,
    -- color = "GitSignsCurrentLineBlame",
    color = function()
      local hl = vim.api.nvim_get_hl(0, { name = "GitSignsCurrentLineBlame" })
      if hl.fg ~= nil then
        return { fg = string.format("#%06x", hl.fg) }
      else
        return "GitSignsCurrentLineBlame"
      end
    end,
    fmt = function(str)
      local l = vim.fn.strchars(str)
      local free_space = vim.opt.columns:get() - get_used_space({ exclude = { "blame" } })
      if free_space < l + 4 then
        str = ""
      end
      if str == "" then
        used_spaces_table["blame"] = 0
      else
        used_spaces_table["blame"] = l + 2
      end
      return str
    end,
    -- TODO: on_click do git show or something
  },
  diagnostics = {
    "diagnostics",
    fmt = function(str)
      local evaled_str = vim.api.nvim_eval_statusline(str, {})
      if str == "" then
        used_spaces_table["diagnostics"] = 0
      else
        used_spaces_table["diagnostics"] = vim.fn.strchars(evaled_str.str) + 2
      end
      return str
    end,
  },
  lsp_status = {
    "lsp_status",
    icon = " ",
    ignore_lsp = { "null-ls" },
    fmt = function(str)
      local l = vim.fn.strchars(str)
      local remain_space = vim.opt.columns:get() - get_used_space({ exclude = { "lsp_status" } })
      if remain_space < l + 4 then
        str = ""
      end
      if str == "" then
        used_spaces_table["lsp_status"] = 0
      else
        used_spaces_table["lsp_status"] = vim.fn.strchars(str) + 2 + 2 + 1
      end
      return str
    end,
  },
  copilot = {
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
    on_click = function() vim.cmd("Copilot toggle") end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["copilot"] = 0
      else
        used_spaces_table["copilot"] = vim.fn.strchars(str) + 2
      end
      return str
    end,
  },
  autoformat = {
    function()
        local autoformat = require("plugins.formatting.autoformat").autoformat
        if
          vim.tbl_contains(
            require("plugins.formatting.autoformat").disable_autoformat_ft,
            vim.api.nvim_get_option_value("filetype", {})
          )
        then
          return "󰚔 off"
        end
        return autoformat and "󰚔 on" or "󰚔 off"
    end,
    on_click = function() vim.cmd("FormatToggle") end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["autoformat"] = 0
      else
        used_spaces_table["autoformat"] = vim.fn.strchars(str) + 2
      end
      return str
    end,
  },
  indent = {
    function() return "Spaces: " .. vim.o.tabstop end,
    cond = function()
      local disabled_filetypes = { "snacks_picker_input", "TelescopePrompt", "oil" }
      for _, ft in ipairs(disabled_filetypes) do
        if vim.o.ft == ft then

          return false
        end
      end
      return true
    end,
    fmt = function(str)
      if str == "" then
        used_spaces_table["indent"] = 0
      else
        used_spaces_table["indent"] = #str + 2
      end
      return str
    end,
  },
  ln = {
    function()
      local line = vim.fn.line(".")
      local total_line = vim.fn.line("$")
      if vim.fn.mode():find("[vV]") then
        return string.format("%d/%d (%d selected)", line, total_line, vim.fn.wordcount().visual_chars)
      else
        return string.format("%d/%d", line, total_line)
      end
    end,
    padding = { left = 1, right = 0 },
    fmt = function(str)
      if str == "" then
        used_spaces_table["ln"] = 0
      else
        used_spaces_table["ln"] = vim.fn.strchars(str) + 1
      end
      return str
    end,
  },
  progress = {
    "progress",
    fmt = function(str)
      local evaled_str = vim.api.nvim_eval_statusline(str, {})
      if str == "" then
        used_spaces_table["progress"] = 0
      else
        used_spaces_table["progress"] = #evaled_str.str + 2
      end
      return str
    end,
  },
}

M.sections = {
  lualine_a = {
    components.mode,
  },
  lualine_b = {
    components.branch,
    components.diff,
  },
  lualine_c = {
    components.fill_space,
    components.filetype,
    components.filename,
  },
  lualine_x = {
    -- TODO: move this to lualine_c without break the centered filename
    components.blame,
    components.diagnostics,
    components.lsp_status,
  },
  lualine_y = {
    components.copilot,
    components.autoformat,
    components.indent,
  },
  lualine_z = {
    components.ln,
    components.progress,
  },
}

return M
