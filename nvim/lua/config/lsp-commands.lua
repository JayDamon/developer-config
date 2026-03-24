local M = {}

function M.setup()
  -- LSP utility commands
  vim.api.nvim_create_user_command('JavaClean', function()
    vim.lsp.buf.execute_command({ command = 'java.clean.workspace' })
    print('Cleaning Java workspace (full rebuild)...')
  end, { desc = 'Clean Java workspace - full rebuild of indexes' })

  vim.api.nvim_create_user_command('Refresh', function()
    vim.lsp.buf.execute_command({ command = 'java.project.refreshProjects' })
    print('Refreshing Java projects...')
  end, { desc = 'Refresh Java projects - reload build files and dependencies' })

  vim.api.nvim_create_user_command('LspRest', function()
    vim.cmd('LspRestart')
    print('Restarting LSP client...')
  end, { desc = 'Restart LSP client - fastest option for config changes' })
end

return M
