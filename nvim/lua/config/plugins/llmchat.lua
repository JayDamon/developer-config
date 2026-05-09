return {
  (_G.llm == "copilot") and {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      {
	"copilotlsp-nvim/copilot-lsp",
      },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    opts = {
      question_header = "## Jay",
      answer_header = "## Copilot",
      error_header = "## Error",
      mappings = {
        complete = {
          detail = "Use@<Tab> or /<Tab> for options.",
          insert = "<Tab>",
        },
        close = {
          normal = "q",
          insert = "<C-c>",
        },
        reset = {
          normal = "<C-x>",
          insert = "<C-x>",
        },
        submit_prompt = {
          normal = "<CR>",
          insert = "<C-Space>",
        },
        accept_diff = {
          normal = "<C-y>",
          insert = "<C-y>",
        },
        show_help = {
          normal = "g?",
        },
      },
    },
    config = function(_, opts)
      local chat = require("CopilotChat")
      chat.setup(opts)
      vim.keymap.set("n", "<leader>cp", "<cmd>CopilotChatToggle<cr>", { desc = "Copilot Chat Toggle " })
    end,
  } or nil,
  (_G.llm == "amazon-q") and pcall(require, 'amazonq') and {
    require('amazonq').setup({
      -- Command passed to `vim.lsp` to start Q LSP. Amazon -- Q LSP is
      -- a NodeJS program, which must be started with `--stdio` flag.
      --      lsp_server_cmd = { 'node', 'path/to/aws-lsp-codewhisperer-token-binary.js', '--stdio' },
      -- IAM Identity Center portal for organisation.
      ssoStartUrl = 'https://view.awsapps.com/start',
      inline_suggest = true,
      -- List of filetypes where the Q will be activated.
      -- Docs: https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-language-ide-support.html
      -- Note: These must be valid Nvim filetypes. For example, Q supports "shell",
      -- but in the filetype name is "sh" (also "bash").
      filetypes = {
        'amazonq', 'bash', 'java', 'python', 'typescript', 'javascript', 'csharp', 'ruby', 'kotlin', 'sh', 'sql', 'c',
        'cpp', 'go', 'rust', 'lua',
      },
      on_chat_open = function()
        vim.cmd [[
          vertical botright split
          set wrap breakindent nonumber norelativenumber nolist
        ]]
      end,
      -- Enable debug mode (for development).
      debug = false,
    }),
    vim.keymap.set('n', '<space>qq', ':AmazonQ<CR>', { noremap = true, silent = true, desc = "Open Amazon Q Chat" })

  } or nil,
}
