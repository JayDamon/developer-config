return {
--  (_G.llm == "copilot") and {
--    "github/copilot.vim",
--  } or nil,
--  (_G.llm == "amazon-q") and {
--    nil
--  } or nil,
  {
    name = 'amazonq',
    url = 'ssh://git.amazon.com/pkg/AmazonQNVim',
    opts = {
      ssoStartUrl = 'https://amzn.awsapps.com/start',
      -- Note: It's normally not necessary to change default `lsp_server_cmd`.
      -- lsp_server_cmd = {
      --   'node',
      --   vim.fn.stdpath('data') .. '/lazy/AmazonQNVim/language-server/build/aws-lsp-codewhisperer-token-binary.js',
      --   '--stdio',
      -- },
    },
  },
}
