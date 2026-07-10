-- clipboard
-- allow you to yank from neovim and C-v to anywhere vice versa
vim.opt.clipboard:prepend({ "unnamed", "unnamedplus" })

-- True when this shell came from SSH, or when the tmux session was last
-- attached from an SSH client. The tmux query covers panes whose shell
-- predates the attach (stale env); needs SSH_TTY in tmux update-environment.
local function is_ssh()
  if vim.env.SSH_TTY then
    return true
  end
  if vim.env.TMUX then
    local line = vim.fn.systemlist({ "tmux", "show-environment", "SSH_TTY" })[1] or ""
    return vim.startswith(line, "SSH_TTY=")
  end
  return false
end

if is_ssh() then
  -- Over SSH: copy via OSC 52 so yanks reach the local machine's clipboard
  -- (needs tmux `set-clipboard on` and a terminal that allows OSC 52).
  -- Paste reads nvim's own register instead of querying the terminal,
  -- since most terminals block OSC 52 reads and it would stall every `p`.
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
elseif _G.IS_WSL and vim.fn.executable("/mnt/c/Windows/System32/win32yank.exe") == 1 then -- you need put win32yank in system32
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = { "/mnt/c/Windows/System32/win32yank.exe", "-i", "--crlf" },
      ["*"] = { "/mnt/c/Windows/System32/win32yank.exe", "-i", "--crlf" },
    },
    paste = {
      ["+"] = { "/mnt/c/Windows/System32/win32yank.exe", "-o", "--lf" },
      ["*"] = { "/mnt/c/Windows/System32/win32yank.exe", "-o", "--lf" },
    },
    cache_enabled = true,
  }
end
