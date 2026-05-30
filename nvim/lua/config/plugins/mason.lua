return {
  "williamboman/mason.nvim",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_tool_installer = require("mason-tool-installer")

    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })


    if vim.g.machine ~= "server" then
      mason_tool_installer.setup({
        ensure_installed = {
          "clangd",
  --        "gopls",
          "google-java-format",
          "prettier",
          "prettierd",
          "eslint_d",
          "lua_ls",
          "jdtls",
          "yamlfix",
          "shellcheck",
          "shfmt",
          "checkstyle",
  --        "delve",
        }
      })
    end
  end,
  build = function()
    pcall(vim.cmd, "MasonUpdate")
  end,
}
