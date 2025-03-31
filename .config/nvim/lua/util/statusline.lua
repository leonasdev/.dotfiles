local M = {}

local mode_width = 0
local branch_width = 0
local diff_width = 0
local filetype_width = 0
local filename_width = 0

--- @param trunc_width number trunctates component when screen width is less then trunc_width
--- @param trunc_len number truncates component to trunc_len number of chars
--- @param hide_width number hides component when window width is smaller then hide_width
--- @param no_ellipsis boolean whether to disable adding '...' at end after truncation
--- return function that can format the component accordingly
local function trunc_fmt(trunc_width, trunc_len, hide_width, no_ellipsis)
  return function(str)
    local win_width = vim.fn.winwidth(0)
    if hide_width and win_width < hide_width then
      return ""
    elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
      return str:sub(1, trunc_len) .. (no_ellipsis and "" or "...")
    end
    return str
  end
end

--- @param trunc_width number trunctates component when screen width is less then trunc_width
--- @param trunc_len number truncates component to trunc_len number of chars
--- @param hide_width number hides component when window width is smaller then hide_width
--- return function that can format the component accordingly
local function trunc_cond(trunc_width, trunc_len, hide_width)
  return function()
    local win_width = vim.fn.winwidth(0)
    if hide_width and win_width < hide_width then
      return false
    elseif trunc_width and trunc_len and win_width < trunc_width then
      return false
    end
    return true
  end
end

M.sections = {
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
    {
      "branch",
      icon = "",
      cond = function()
        local should_show = vim.opt.columns:get() > 60
        if not should_show then
          branch_width = 0
        end
        return should_show
      end,
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
      cond = function()
        local should_show = vim.opt.columns:get() > 60
        if not should_show then
          diff_width = 0
        end
        return should_show
      end,
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
        local fill_space = string.rep(" ", math.floor((win_width - filename_width - filetype_width) / 2) - used_space)
        return fill_space
      end,
      padding = { left = 0, right = 0 },
      cond = function() return vim.opt.columns:get() > 60 end,
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
      fmt = function(filename)
        if filename == "" then
          filename_width = 0
          return ""
        end

        local used_space = mode_width + branch_width + diff_width
        local win_width = vim.opt.columns:get()
        local free_space = (math.floor(win_width / 2) - used_space) * 2

        -- if the filename is longer than the free space, use the filename
        if free_space < #filename + filetype_width + 10 then
          filename = vim.fn.expand("%:t")
        end

        -- if the filename is still longer than the free space, cut the filename
        if free_space < #filename + filetype_width + 10 then
          local end_idx = free_space - filetype_width - 13
          if end_idx < 0 then
            return ""
          end
          filename = string.sub(filename, 1, end_idx) .. "..."
        end

        filename_width = #filename + 2 -- 2 is the length of padding

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
    },
  },
  lualine_x = {
    -- TODO: move this to lualine_c without break the centered filename
    {
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
      color = function()
        local hl = vim.api.nvim_get_hl(0, { name = "GitSignsCurrentLineBlame" })
        return { fg = string.format("#%06x", hl.fg) }
      end,
      cond = trunc_cond(120, 20, 60),
      -- TODO: on_click do git show or something
    },
    { "diagnostics" },
    {
      "lsp_status",
      icon = " ",
      ignore_lsp = { "null-ls" },
    },
  },
  lualine_y = {
    -- "progress",
    -- {
    --   "encoding",
    --   cond = function() return vim.opt.columns:get() > 80 end,
    -- },
    -- {
    --   function()
    --     local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
    --     return enc:lower() .. "[" .. vim.bo.fileformat:lower() .. "]"
    --   end,
    -- },
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
      on_click = function() vim.cmd("Copilot toggle") end,
    },
    {
      function()
        local autoformat = require("plugins.formatting.autoformat").autoformat
        return autoformat and "󰚔 on" or "󰚔 off"
      end,
      on_click = function() vim.cmd("FormatToggle") end,
    },
    {
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
    },
  },
  lualine_z = {
    -- {
    --   "location",
    --   padding = { left = 1, right = 0 },
    -- },
    {
      function()
        local line = vim.fn.line(".")
        local total_line = vim.fn.line("$")
        return string.format("%d/%d", line, total_line)
      end,
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
}

return M
