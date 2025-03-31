return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    {
      "<C-p>",
      function()
        local layout = {
          preview = false,
          layout = {
            backdrop = false,
            row = 1,
            width = 0.4,
            min_width = 80,
            height = 0.4,
            border = "rounded",
            box = "vertical",
            {
              win = "input",
              height = 1,
              border = "none",
              title = "{title} {live} {flags}",
              title_pos = "center",
            },
            { win = "list", border = "hpad" },
            { win = "preview", title = "{preview}", border = "rounded" },
          },
        }
        if vim.loop.fs_stat(vim.loop.cwd() .. "/.git") then
          Snacks.picker.git_files({
            layout = layout,
            submodules = true,
          })
        else
          Snacks.picker.files({
            layout = layout,
            hidden = true,
            ignored = true,
          })
        end
      end,
      mode = "n",
    },
    {
      "<C-f>",
      function()
        Snacks.picker.grep({
          layout = {
            preview = "main",
            layout = {
              box = "vertical",
              backdrop = false,
              width = 0,
              height = 0.4,
              position = "bottom",
              border = "top",
              title = " {title} {live}",
              title_pos = "left",
              { win = "input", height = 1, border = "bottom" },
              {
                box = "horizontal",
                { win = "list", border = "none" },
                { win = "preview", title = "{preview}", width = 0.6, border = "left" },
              },
            },
          },
          ignored = true,
          hidden = true,
        })
      end,
      mode = "n",
    },
    {
      "<C-t>",
      function() Snacks.picker.resume() end,
      mode = "n",
    },
  },
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    rename = { enabled = true },
    words = {
      enabled = true,
      modes = { "n" },
    },
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
            ["<C-BS>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
            ["<c-s>"] = { "edit_vsplit", mode = { "i", "n" } },
            ["<c-x>"] = { "edit_split", mode = { "i", "n" } },
          },
        },
      },
    },
  },
}
