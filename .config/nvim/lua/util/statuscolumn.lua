local M = {}

local ft_ignore = {
  alpha = true,
  ["neo-tree"] = true,
  oil = true,
  snacks_dashboard = true,
}

local function get_signs(bufnr, lnum)
  local diag, dap, git
  local ok, marks = pcall(
    vim.api.nvim_buf_get_extmarks,
    bufnr,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )
  if not ok then
    return nil, nil, nil
  end

  for _, m in ipairs(marks) do
    local d = m[4]
    if d and d.sign_text then
      local hl = d.sign_hl_group or ""
      local entry = { text = d.sign_text, hl = hl, priority = d.priority or 0 }
      if hl:find("^Diagnostic") then
        if not diag or entry.priority > diag.priority then
          diag = entry
        end
      elseif hl:find("^Dap") then
        if not dap or entry.priority > dap.priority then
          dap = entry
        end
      elseif hl:find("^GitSigns") then
        if not git or entry.priority > git.priority then
          git = entry
        end
      end
    end
  end
  return diag, dap, git
end

local function render_sign(sign)
  if not sign then
    return "  "
  end
  local text = sign.text or ""
  local dw = vim.fn.strdisplaywidth(text)
  if dw < 2 then
    text = text .. string.rep(" ", 2 - dw)
  end
  if sign.hl and sign.hl ~= "" then
    return "%#" .. sign.hl .. "#" .. text .. "%*"
  end
  return text
end

-- Click handler: toggle a DAP breakpoint at the clicked buffer line.
-- Called via `%@v:lua.statuscolumn_toggle_breakpoint@...%X` markers.
function _G.statuscolumn_toggle_breakpoint(_minwid, _nclicks, button, _mods)
  if button ~= "l" then
    return
  end
  local pos = vim.fn.getmousepos()
  if not pos or pos.line == 0 then
    return
  end
  local ok, dap = pcall(require, "dap")
  if not ok then
    return
  end
  vim.api.nvim_win_call(pos.winid, function()
    vim.api.nvim_win_set_cursor(0, { pos.line, 0 })
    dap.toggle_breakpoint()
  end)
end

local function clickable(content) return "%@v:lua.statuscolumn_toggle_breakpoint@" .. content .. "%X" end

-- Approximate how many display rows the current physical line spans.
-- Used to pick "└" (last wrap) vs. "├" (middle wrap) for continuation rows.
local function get_num_wraps(winid)
  return vim.api.nvim_win_call(winid, function()
    local wo = vim.wo[winid]
    local winwidth = vim.api.nvim_win_get_width(winid)
    local numberwidth = (wo.number or wo.relativenumber)
        and math.max(wo.numberwidth, #tostring(vim.fn.line("$")))
      or 0
    local signwidth = 6 -- 3 sign slots * 2 chars (diag / dap / git)
    local foldwidth = tonumber(wo.foldcolumn) or 0
    local bufferwidth = winwidth - numberwidth - signwidth - foldwidth
    if bufferwidth <= 0 then
      return 0
    end
    local line = vim.fn.getline(vim.v.lnum)
    return math.floor(vim.fn.strdisplaywidth(line) / bufferwidth)
  end)
end

local function get_lnum(winid)
  -- virtual line from extmark virt_lines
  if vim.v.virtnum < 0 then
    return "%=-"
  end

  local wo = vim.wo[winid]

  -- visual-mode line range highlight
  local v_hl = ""
  ---@diagnostic disable-next-line: undefined-field
  local mode = vim.fn.strtrans(vim.fn.mode()):lower():gsub("%W", "")
  if mode == "v" then
    local ok, util = pcall(require, "util")
    if ok then
      local v_range = util.get_visual_range()
      if vim.v.lnum >= v_range[1] and vim.v.lnum <= v_range[3] then
        v_hl = "%#CursorLineNr#"
      end
    end
  end
  local v_hl_end = v_hl ~= "" and "%*" or ""

  -- wrap continuation row
  if vim.v.virtnum > 0 and (wo.number or wo.relativenumber) then
    local marker = vim.v.virtnum == get_num_wraps(winid) and "└" or "├"
    return v_hl .. "%=" .. marker .. v_hl_end
  end

  -- regular line number (relculright = true: current line shows absolute,
  -- right-aligned; other lines show relative if relativenumber is set)
  local num
  if wo.relativenumber and vim.v.relnum ~= 0 then
    num = tostring(vim.v.relnum)
  elseif wo.number or wo.relativenumber then
    num = tostring(vim.v.lnum)
  else
    return v_hl .. v_hl_end
  end
  return v_hl .. "%=" .. num .. v_hl_end
end

function M.draw()
  -- During statuscolumn evaluation neovim sets `g:statusline_winid` to the
  -- window being drawn. We must NOT rely on `vim.bo` / `vim.wo` (which point
  -- at the *active* window), otherwise a focused floating window like
  -- oil.open_float() will leak its filetype/number settings into every other
  -- window's redraw and blank them out.
  local winid = vim.g.statusline_winid
  if not winid or winid == -1 then
    winid = vim.api.nvim_get_current_win()
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)

  if ft_ignore[vim.bo[bufnr].filetype] then
    return ""
  end

  local diag, dap, git
  if vim.v.virtnum == 0 then
    diag, dap, git = get_signs(bufnr, vim.v.lnum)
  end

  return render_sign(diag) .. clickable(render_sign(dap) .. get_lnum(winid)) .. render_sign(git)
end

return M
