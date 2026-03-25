-- Read bemol workspace folders for cross-package resolution
local function get_bemol_folders(root)
  if not root then return {}, {} end
  local file = io.open(root .. "/.bemol/ws_root_folders")
  if not file then return {}, {} end
  local folders, init_folders = {}, {}
  for line in file:lines() do
    if vim.fn.isdirectory(line) == 1 then
      table.insert(folders, line)
      table.insert(init_folders, "file://" .. line)
    end
  end
  file:close()
  return folders, init_folders
end

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
      local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
      local ws_folders, init_folders = get_bemol_folders(root_dir)

      -- Lombok support
      local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
      local cmd = { vim.fn.exepath("jdtls") }
      if vim.uv.fs_stat(lombok_jar) then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
      end
      -- More memory for large workspaces
      table.insert(cmd, "--jvm-arg=-Xmx4g")
      table.insert(cmd, "--jvm-arg=-XX:+UseG1GC")

      local on_attach = function(client, bufnr)
        local lsp_keymaps = require('config.lsp-keymaps')
        local lsp_commands = require('config.lsp-commands')
        lsp_keymaps.setup_keymaps(client, bufnr)
        lsp_commands.setup()

        -- jdtls-specific keymaps
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<space>oi', jdtls.organize_imports, bufopts)
        vim.keymap.set('n', '<space>ev', jdtls.extract_variable, bufopts)
        vim.keymap.set('n', '<space>ec', jdtls.extract_constant, bufopts)
        vim.keymap.set('v', '<space>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], bufopts)

        -- Also add via add_workspace_folder as belt-and-suspenders
        for _, folder in ipairs(ws_folders) do
          vim.lsp.buf.add_workspace_folder(folder)
        end
      end

      local config = {
        name = 'jdtls',
        on_attach = on_attach,
        root_dir = root_dir,
        cmd = cmd,
        -- Pass bemol folders at init time so jdtls knows about them immediately
        init_options = {
          workspaceFolders = init_folders,
        },
        settings = {
          java = {
            referencesCodeLens = { enabled = false },
            implementationsCodeLens = { enabled = false },
            -- autobuild = { enabled = false },  -- toggle: disables real-time diagnostics but speeds up large projects
            format = {
              enabled = {
                url = "~/dotfiles/config/simba-checkstyle-rules.xml",
                profile = "SimbaStyle",
              },
            },
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
            completion = {
              favoriteStaticMembers = {
                "org.hamcrest.MatcherAssert.assertThat",
                "org.hamcrest.Matchers.*",
                "org.hamcrest.CoreMatchers.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.mockito.Mockito.*",
                "org.mockito.ArgumentMatchers.*",
                "java.util.Objects.requireNonNull",
                "java.util.Objects.requireNonNullElse",
                "org.assertj.core.api.Assertions.assertThat",
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

      -- Patch client detection for decompiled files
      vim.defer_fn(function()
        local jdtls_util = require('jdtls.util')
        local original_get_clients = jdtls_util.get_clients
        jdtls_util.get_clients = function(filter)
          local clients = original_get_clients(filter)
          if #clients == 0 and filter and filter.name == "jdtls" then
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
