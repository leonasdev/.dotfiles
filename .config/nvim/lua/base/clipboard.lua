-- clipboard
-- allow you to yank from neovim and C-v to anywhere vice versa
vim.opt.clipboard:prepend({ "unnamed", "unnamedplus" })

if _G.IS_WSL and vim.fn.executable("/mnt/c/Windows/System32/win32yank.exe") == 1 then -- you need put win32yank in system32
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
