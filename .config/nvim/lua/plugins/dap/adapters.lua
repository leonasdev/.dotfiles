return {
  debugpy = {
    name = "debugpy", -- for mason installer
    path = _G.IS_WINDOWS and vim.fn.stdpath("data") .. "mason\\packages\\debugpy\\venv\\bin\\python"
      or vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
  },
  delve = {
    name = "delve", -- for mason installer
  },
  codelldb = {
    name = "codelldb",
  },
}
