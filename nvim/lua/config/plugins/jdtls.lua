return {
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    dependencies = { 'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim' },
    config = function()
      vim.env.JAVA_HOME = '/usr/lib/jvm/java-21-amazon-corretto'
      local jdtls = require('jdtls')

      local root_dir = require('jdtls.setup').find_root({ 'packageInfo', 'Config', '.git', 'mvnw', 'gradlew' })
      local home = os.getenv("HOME")
      local jdtls_path = vim.fn.expand "$MASON/packages/jdtls"
      local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

      local on_attach = function(client, bufnr)
        local lsp_keymaps = require('config.lsp-keymaps')
        local lsp_commands = require('config.lsp-commands')

        -- Set up common LSP keymaps
        lsp_keymaps.setup_keymaps(client, bufnr)
        
        -- Set up LSP commands
        lsp_commands.setup()

        -- Add jdtls-specific keymaps
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<space>oi', jdtls.organize_imports, bufopts)
        vim.keymap.set('n', '<space>ev', jdtls.extract_variable, bufopts)
        vim.keymap.set('n', '<space>ec', jdtls.extract_constant, bufopts)
        vim.keymap.set('v', '<space>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], bufopts)

        -- Add bemol workspace folders with validation
        if root_dir then
          local file = io.open(root_dir .. "/.bemol/ws_root_folders")
          if file then
            for line in file:lines() do
              -- Check if directory exists and isn't already added
              if vim.fn.isdirectory(line) == 1 then
                local current_folders = vim.lsp.buf.list_workspace_folders()
                local already_added = false
                for _, folder in ipairs(current_folders) do
                  if folder == line then
                    already_added = true
                    break
                  end
                end
                if not already_added then
                  vim.lsp.buf.add_workspace_folder(line)

                  -- Also add source directories within the workspace
                  local main_src = line .. "/main/java"
                  local test_src = line .. "/test/java"
                  if vim.fn.isdirectory(main_src) == 1 then
                    vim.lsp.buf.add_workspace_folder(main_src)
                  end
                  if vim.fn.isdirectory(test_src) == 1 then
                    vim.lsp.buf.add_workspace_folder(test_src)
                  end
                end
              end
            end
            file:close()
          end
        end
      end
      local config = {
        name = 'jdtls',
        on_attach = on_attach,
        root_dir = root_dir,
        cmd = { vim.fn.exepath("jdtls") },
        -- cmd = { 'jdtls' }
        -- cmd = {
        --   '/usr/lib/jvm/java-21-amazon-corretto/bin/java',
        --   '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        --   '-Dosgi.bundles.defaultStartLevel=4',
        --   '-Declipse.product=org.eclipse.jdt.ls.core.product',
        --   '-Dlog.protocol=true',
        --   '-Dlog.level=ALL',
        --   '-Xmx4g',
        --   '--add-modules=ALL-SYSTEM',
        --   '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        --   '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        --   -- If you use lombok, download the lombok jar and place it in ~/.local/share/eclipse
        --   -- '-javaagent:' .. home .. '/.local/share/eclipse/lombok.jar',
        --
        --   -- The jar file is located where jdtls was installed. This will need to be updated
        --   -- to the location where you installed jdtls
        --   '-jar', vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
        --
        --   -- The configuration for jdtls is also placed where jdtls was installed. This will
        --   -- need to be updated depending on your environment
        --   '-configuration', jdtls_path .. "/config_linux/",
        --
        --   -- Use the workspace_folder defined above to store data for this project
        --   '-data', workspace_folder,
        -- },
        -- --   root_dir = require('jdtls.setup').find_root({ 'pom.xml', '.git', 'mvnw', 'gradlew' }),
        settings = {
          java = {
            referencesCodeLens = true,
            implementationCodeLens = true,
            format = {
              enabled = {
                url = "~/dotfiles/config/simba-checkstyle-rules.xml",
                profile = "SimbaStyle",
              },
            },
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
            -- contentProvider = { preferred = 'none' },
            completion = {
              favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.mockito.Mockito.*",
                "org.mockito.ArgumentMatchers.*",
                "org.mockito.Mockito.*",
                "org.junit.jupiter.api.Assertions.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.assertj.core.api.Assertions.assertThat",
                "org.mockito.Mockito.*",
              },
              filteredTypes = {
                "com.sun.*",
                "io.micrometer.shaded.*",
                "java.awt.*",
                "jdk.*",
                "sun.*",
              },
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
            codeGeneration = {
              toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
              },
              hashCodeEquals = {
                useJava7Objects = true,
              },
              useBlocks = true,
            },
            configuration = {
              runtimes = {
                {
                  name = "JavaSE-17",
                  path = "/usr/lib/jvm/java-17-amazon-corretto.x86_64",
                },
                {
                  name = "JavaSE-11",
                  path = "/usr/lib/jvm/java-17-amazon-corretto",
                },
                {
                  name = "JavaSE-21",
                  path = "/usr/lib/jvm/java-21-amazon-corretto",
                },
              },
            },
          },
        },
      }
      jdtls.start_or_attach(config)

      -- Global fix for cursor positioning in decompiled files
      local original_set_cursor = vim.api.nvim_win_set_cursor
      vim.api.nvim_win_set_cursor = function(win, pos)
        local buf = vim.api.nvim_win_get_buf(win)
        local line_count = vim.api.nvim_buf_line_count(buf)
        if pos[1] > line_count then
          pos[1] = math.max(1, line_count)
        end
        return original_set_cursor(win, pos)
      end

      -- Disable nvim-jdtls autocmd that breaks decompilation
      vim.defer_fn(function()
        -- Don't clear the autocmds, instead patch the client detection
        local jdtls_util = require('jdtls.util')
        local original_get_clients = jdtls_util.get_clients
        jdtls_util.get_clients = function(filter)
          local clients = original_get_clients(filter)
          if #clients == 0 and filter and filter.name == "jdtls" then
            -- Try to find any client that looks like jdtls
            local all_clients = vim.lsp.get_active_clients()
            for _, client in ipairs(all_clients) do
              if client.name:match("jdtls") or client.config.name == "jdtls" then
                return {client}
              end
            end
          end
          return clients
        end
      end, 100)

    end,
  },
}
