return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")
    conform.setup({
      formatters_by_ft = {
        html = { "htmlbeautifier" },
        bash = { "beautysh" },
        yaml = { "yamlfix" },
        css = { "prettierd" },
        scss = { "prettierd" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        sh = { "shfmt" },
        conf = { "shfmt" },
        go = { "gofmt" },
      },
--      format_on_save = {
--        timeout_ms = 500,
--        lsp_fallback = true,
--      }
      --      formatters = {
      --        prettierd = {
      --          condition = function()
      --            return vim.loop.fs_realpath(".prettierc.js") ~= nil or vim.loop.fs_realpath(".prettierc.mjs") ~= nil
      --          end,
      --        }
      --      }
    })

    vim.keymap.set({ "n", "v" }, "<leader>l", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end
}
