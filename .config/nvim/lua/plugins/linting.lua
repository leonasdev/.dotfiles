return {
  { -- TODO: refactor
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      linters_by_ft = {
        python = { "pylint" },
        go = { "staticcheck" },
        dockerfile = { "hadolint" },
      },
      events = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      local function debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          if not timer then
            return
          end
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = debounce(100, function() lint.try_lint() end),
      })

      vim.api.nvim_create_user_command("LintInfo", function()
        local filetype = vim.bo.filetype
        local linters_by_ft = require("lint").linters_by_ft[filetype]

        if linters_by_ft then
          print("Linters for " .. filetype .. ": " .. table.concat(linters_by_ft, ", "))
        else
          print("No linters configured for filetype: " .. filetype)
        end
      end, {})
    end,
  },
}
