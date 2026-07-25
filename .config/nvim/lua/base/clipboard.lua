-- clipboard
-- allow you to yank from neovim and C-v to anywhere vice versa
vim.opt.clipboard:prepend({ "unnamed", "unnamedplus" })

-- "Am I over SSH?" has no answer worth asking for. A remote client and the
-- machine's own terminal can sit on the same tmux session at once, and nothing
-- reachable from here says which screen you are currently looking at: the
-- process environment is frozen at pane birth (a popup opened over SSH still
-- advertises a connection that died weeks ago), and tmux's session environment
-- keeps a single value that the most recent attach overwrites.
--
-- So copy to both places, every time:
--   * the native tool, for the machine nvim is actually running on
--   * OSC 52, which tmux forwards to every attached client, so a remote
--     terminal drops the same text on *its* machine's clipboard
local native
if _G.IS_WSL and vim.fn.executable("/mnt/c/Windows/System32/win32yank.exe") == 1 then -- you need put win32yank in system32
  native = {
    copy = { "/mnt/c/Windows/System32/win32yank.exe", "-i", "--crlf" },
    paste = { "/mnt/c/Windows/System32/win32yank.exe", "-o", "--lf" },
  }
elseif vim.fn.has("mac") == 1 then
  native = { copy = { "pbcopy" }, paste = { "pbpaste" } }
end
-- Anywhere else (a plain remote box with no clipboard tool): OSC 52 alone.

local osc52 = require("vim.ui.clipboard.osc52")

local function copy(reg)
  local emit = osc52.copy(reg)
  if not native then
    return emit
  end
  return function(lines, regtype)
    emit(lines, regtype)
    -- Native tool second: terminals cap the size of an OSC 52 payload, so if a
    -- big yank comes back truncated the local clipboard still gets it whole.
    vim.fn.systemlist(native.copy, lines, 1)
  end
end

-- Paste reads the native clipboard. Reading back over OSC 52 needs a reply
-- most terminals refuse to send, which stalls every `p`; to paste something
-- copied on the remote side use the terminal's own paste (Cmd/Ctrl-V), which
-- arrives as keystrokes and never touches this provider.
local function paste_from_register()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end
local paste = native and native.paste or paste_from_register

vim.g.clipboard = {
  name = native and (native.copy[1]:match("[^/]+$") .. "+osc52") or "OSC 52",
  copy = { ["+"] = copy("+"), ["*"] = copy("*") },
  paste = { ["+"] = paste, ["*"] = paste },
}
