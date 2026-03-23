return {
  {
    'j-hui/fidget.nvim',
    opts = {
      progress = {
        display = {
          render_limit = 16,          -- How many LSP messages to show at once
          done_ttl = 3,               -- How long a message should persist after completion
          done_icon = "✔",            -- Icon shown when all LSP progress tasks are complete
        },
      },
      notification = {
        window = {
          winblend = 100,             -- Background color opacity in the notification window
        },
      },
    },
  },
}
