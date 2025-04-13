-- TODO: move this to plugins?
local M = {}

---A helper function to find configurations
---@param config_names string[] A list of config names you want to find (e.g. { ".stylua.toml", "stylua.toml" })
---@param default_dir string Default config directory (e.g. vim.fn.stdpath("config") .. "/lua/plugins/formatting/configs/")
---@return string config_dir The directory of first found configuration (project's config > default's config)
function M.config_finder(config_names, default_dir)
  -- prevent that user not provide last seperator
  if string.sub(default_dir, string.len(default_dir)) ~= "/" then
    default_dir = default_dir .. "/"
  end

  local found_config = ""

  -- search from project recursively
  for _, name in ipairs(config_names) do
    local found_root = vim.fs.root(0, name)
    if found_root then
      found_config = found_root .. "/" .. name
      if _G.IS_WINDOWS then
        found_config = string.gsub(found_config, "/", "\\\\")
      end
      return found_config
    end
  end

  -- search from defalut_dir
  for _, name in ipairs(config_names) do
    if vim.loop.fs_stat(default_dir .. name) then
      found_config = default_dir .. name
      if _G.IS_WINDOWS then
        found_config = string.gsub(found_config, "/", "\\\\")
      end
      return found_config
    end
  end

  return found_config
end

--- Create a button entity to use with the alpha dashboard
--- @param sc string The keybinding string to convert to a button
--- @param txt string The explanation text of what the keybinding does
--- @param keybind string? optional
--- @param keybind_opts table? optional
--- @return table # A button entity table for an alpha configuration
function M.button(sc, txt, keybind, keybind_opts)
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
function M.get_greeting(name)
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

-- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
function M.char_byte_count(s, i)
  if not s or s == "" then
    return 1
  end

  local char = string.byte(s, i or 1)

  -- Get byte count of unicode character (RFC 3629)
  if char > 0 and char <= 127 then
    return 1
  elseif char >= 194 and char <= 223 then
    return 2
  elseif char >= 224 and char <= 239 then
    return 3
  elseif char >= 240 and char <= 244 then
    return 4
  end
end

function M.char_on_pos(pos)
  pos = pos or vim.fn.getpos(".")
  return tostring(vim.fn.getline(pos[1])):sub(pos[2], pos[2])
end

function M.get_visual_range()
  local sr, sc = unpack(vim.fn.getpos("v"), 2, 3)
  local er, ec = unpack(vim.fn.getpos("."), 2, 3)

  -- To correct work with non-single byte chars
  local byte_c = M.char_byte_count(M.char_on_pos({ er, ec }))
  ec = ec + (byte_c - 1)

  local range = {}

  if sr == er then
    local cols = sc >= ec and { ec, sc } or { sc, ec }
    range = { sr, cols[1] - 1, er, cols[2] }
  elseif sr > er then
    range = { er, ec - 1, sr, sc }
  else
    range = { sr, sc - 1, er, ec }
  end

  return range
end

function M.close_diagnostic_float()
  if vim.g.diagnostic_float_win then
    pcall(vim.api.nvim_win_close, vim.g.diagnostic_float_win, false)
    vim.g.diagnostic_float_win = nil
  end
end

return M
