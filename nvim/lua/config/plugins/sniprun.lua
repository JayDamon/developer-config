return {
  {
    "michaelb/sniprun",
    build = "sh install.sh",
    config = function()
      require("sniprun").setup({
        selected_interpreters = { "Bash_original" },
        display = { "Terminal", "VirtualTextOk", "Api", "TerminalWithCode" },
        show_no_output = {
          "Terminal",
          "VirtualText",
        },
        interpreter_options = {
          Bash_original = {
            use_on_filetypes = {"sh", "bash"},
            -- Use login shell to get full environment
            supported_filetypes = {"sh", "bash"},
          },
        },
        -- Use system shell with environment
        bash_path = "bash",
        snipruncolors = {
          SniprunVirtualTextOk = { bg = "#66eeff", fg = "#000000", ctermbg = "Cyan", ctermfg = "Black" },
          SniprunFloatingWinOk = { fg = "#66eeff", ctermfg = "Cyan" },
          SniprunVirtualTextErr = { bg = "#881515", fg = "#000000", ctermbg = "DarkRed", ctermfg = "Black" },
          SniprunFloatingWinErr = { fg = "#881515", ctermfg = "DarkRed" },
        },
      })

      -- Function to run code between ### delimiters
      local function run_between_delimiters()
        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        -- Find the ### delimiters around current cursor
        local start_line, end_line = nil, nil

        -- Search backwards for start delimiter
        for i = current_line, 1, -1 do
          if lines[i] and lines[i]:match("^###") then
            start_line = i
            break
          end
        end

        -- Search forwards for end delimiter
        for i = current_line, #lines do
          if lines[i] and lines[i]:match("^###") and i > (start_line or 0) then
            end_line = i
            break
          end
        end

        if start_line and end_line and start_line < end_line then
          -- Select the range between delimiters (excluding the ### lines)
          vim.api.nvim_win_set_cursor(0, {start_line + 1, 0})
          vim.cmd("normal! V")
          vim.api.nvim_win_set_cursor(0, {end_line - 1, 0})
          vim.cmd("SnipRun")
          vim.cmd("normal! <Esc>")
        else
          vim.notify("No ### delimiters found around cursor", vim.log.levels.WARN)
        end
      end

      vim.keymap.set("n", "<leader>tn", run_between_delimiters, { desc = "Run code between ### delimiters" })
      
      -- Debug function to show what would be executed
      vim.keymap.set("n", "<leader>rp", function()
        local line = vim.api.nvim_get_current_line()
        print("Would execute: " .. line)
      end, { desc = "Preview current line" })
      
      vim.keymap.set("v", "<leader>rp", function()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
        print("Would execute:")
        for i, line in ipairs(lines) do
          print(i .. ": " .. line)
        end
      end, { desc = "Preview selection" })
    end,
    keys = {
      { "<leader>rr", "<cmd>SnipRun<cr>", desc = "Run code snippet" },
      { "<leader>rf", "<cmd>%SnipRun<cr>", desc = "Run entire file" },
      { "<leader>rr", "<cmd>SnipRun<cr>", mode = "v", desc = "Run selection" },
      { "<leader>rc", "<cmd>SnipClose<cr>", desc = "Close sniprun" },
      { "<leader>rs", "<cmd>SnipReset<cr>", desc = "Reset sniprun" },
      { "<leader>ri", "<cmd>SnipInfo<cr>", desc = "Sniprun info" },
      { "<leader>rd", "<cmd>SnipLive<cr>", desc = "Toggle sniprun live mode" },
    },
  },
}
