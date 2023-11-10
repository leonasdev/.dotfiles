local M = {}

---A helper function to find configurations
---@param config_names string[] A list of config names you want to find (e.g. { ".stylua.toml", "stylua.toml" })
---@param default_dir string Default config directory (e.g. vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/")
---@return string config_dir The directory of first found configuration (project's config > default's config)
M.config_finder = function(config_names, default_dir)
  -- prevent that user not provide last seperator
  if string.sub(default_dir, string.len(default_dir)) ~= "/" then
    default_dir = default_dir .. "/"
  end

  local config_dir = ""

  -- search from project recursively
  for _, name in ipairs(config_names) do
    local found_root = require("lspconfig").util.root_pattern(name)(vim.loop.cwd())
    if found_root then
      config_dir = found_root .. "/" .. name
      if _G.IS_WINDOWS then
        config_dir = string.gsub(config_dir, "/", "\\\\")
      end
      return config_dir
    end
  end

  -- search from defalut_dir
  for _, name in ipairs(config_names) do
    if vim.loop.fs_stat(default_dir .. name) then
      config_dir = default_dir .. name
      if _G.IS_WINDOWS then
        config_dir = string.gsub(config_dir, "/", "\\\\")
      end
      return config_dir
    end
  end

  return config_dir
end

--- Create a button entity to use with the alpha dashboard
--- @param sc string The keybinding string to convert to a button
--- @param txt string The explanation text of what the keybinding does
--- @param keybind string? optional
--- @param keybind_opts table? optional
--- @return table # A button entity table for an alpha configuration
M.button = function(sc, txt, keybind, keybind_opts)
  local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

  local opts = {
    position = "center",
    shortcut = sc,
    cursor = 3,
    width = 30,
    align_shortcut = "right",
    hl_shortcut = "Keyword",
  }
  if keybind then
    keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
    opts.keymap = { "n", sc_, keybind, keybind_opts }
  end

  local function on_press()
    local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
    vim.api.nvim_feedkeys(key, "t", false)
  end

  return {
    type = "button",
    val = txt,
    on_press = on_press,
    opts = opts,
  }
end

--- Get greeting message based on current time and username
--- @param name string Username
M.get_greeting = function(name)
  local tableTime = os.date("*t")
  local hour = tableTime.hour
  local greetingsTable = {
    [1] = "󰙃  Why are you still up, " .. name .. "?",
    [2] = "  Good morning, " .. name,
    [3] = "  Good afternoon, " .. name,
    [4] = "󰖔  Good evening, " .. name,
  }
  local greetingIndex = 0
  if hour >= 23 or hour < 7 then
    greetingIndex = 1
  elseif hour < 12 then
    greetingIndex = 2
  elseif hour >= 12 and hour < 18 then
    greetingIndex = 3
  elseif hour >= 18 and hour < 23 then
    greetingIndex = 4
  end
  return greetingsTable[greetingIndex]
end

return M
