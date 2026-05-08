local workspaces = {}

if vim.g.machine == "work" then
  table.insert(workspaces, { name = "work", path = "~/Documents/obsidian/AWS" })
elseif vim.g.machine == "home" then
  table.insert(workspaces, { name = "personal", path = "~/Notes/PersonalNotes" })
end

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  enabled = #workspaces > 0,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = workspaces,

    completion = {
      nvim_cmp = false,
      min_chars = 2,
    },

    mappings = {
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
    },

    picker = {
      name = "telescope.nvim",
    },
  },
  keys = {
    { "<leader>oo", "<cmd>ObsidianQuickSwitch<CR>", desc = "Open note" },
    { "<leader>on", "<cmd>ObsidianNew<CR>", desc = "New note" },
    { "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Search notes" },
    { "<leader>od", "<cmd>ObsidianToday<CR>", desc = "Daily note" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<CR>", desc = "Backlinks" },
    { "<leader>ot", "<cmd>ObsidianTags<CR>", desc = "Search tags" },
  },
}
