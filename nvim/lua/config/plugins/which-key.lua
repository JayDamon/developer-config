return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 300,
    icons = { mappings = true },
    spec = {
      { "<leader>h", group = "git hunks" },
      { "<leader>r", group = "run/sniprun" },
      { "<leader>t", group = "toggle" },
      { "<leader>f", group = "find" },
      { "<leader>e", group = "explore" },
      { "<leader>w", group = "workspace" },
    },
  },
}
