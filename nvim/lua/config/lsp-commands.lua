local M = {}

function M.setup()
  -- LSP utility commands
  vim.api.nvim_create_user_command('JavaClean', function()
    local clients = vim.lsp.get_clients({ name = 'jdtls' })
    if #clients == 0 then print('No jdtls client attached') return end
    clients[1]:exec_cmd({ command = 'java.clean.workspace' })
    print('Cleaning Java workspace (full rebuild)...')
  end, { desc = 'Clean Java workspace - full rebuild of indexes' })

  vim.api.nvim_create_user_command('Refresh', function()
    local clients = vim.lsp.get_clients({ name = 'jdtls' })
    if #clients == 0 then print('No jdtls client attached') return end
    clients[1]:exec_cmd({ command = 'java.project.refreshProjects' })
    print('Refreshing Java projects...')
  end, { desc = 'Refresh Java projects - reload build files and dependencies' })

  vim.api.nvim_create_user_command('LspRest', function()
    vim.cmd('LspRestart')
    print('Restarting LSP client...')
  end, { desc = 'Restart LSP client - fastest option for config changes' })

  vim.api.nvim_create_user_command('Bemol', function()
    local root = vim.fs.find({ 'packageInfo' }, { upward = true })[1]
    if not root then
      print('Not in a Brazil workspace')
      return
    end
    local ws_dir = vim.fn.fnamemodify(root, ':h')
    local fidget = require('fidget')
    local handle = fidget.progress.handle.create({ title = 'Bemol', message = 'Resolving dependencies...', lsp_client = { name = 'bemol' } })
    vim.fn.jobstart({ 'bemol' }, {
      cwd = ws_dir,
      stderr_buffered = true,
      on_stderr = function(_, data)
        vim.schedule(function()
          local msg = table.concat(data, '\n'):gsub('%s+$', '')
          if msg ~= '' then handle.message = msg end
        end)
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            handle.message = 'Complete. Run :JavaClean to reload.'
            handle:finish()
          else
            handle.message = 'Failed (exit ' .. code .. ')'
            handle:finish()
          end
        end)
      end,
    })
  end, { desc = 'Run bemol to regenerate LSP config for Brazil workspace' })
end

return M
