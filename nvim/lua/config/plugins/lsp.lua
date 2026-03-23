return {
  "VonHeikemen/lsp-zero.nvim",
  branch = "v2.x",
  dependencies = {
    -- LSP Support
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        'seghen/blink.cmp',
        {
          "folke/lazydev.nvim",
          ft = "lua",
          opts = {
            library = {
              { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
          },
        },
      },
      config = function()
        local capabilities = require('blink.cmp').get_lsp_capabilities()
        local lsp_keymaps = require('config.lsp-keymaps')
        
        require("lspconfig").lua_ls.setup { capabilities = capabilities }

        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then return end

            -- Set up common LSP keymaps
            lsp_keymaps.setup_keymaps(client, args.buf)

            -- I Am not sure if this is doing anything anymore
            --  It is supposed to provide format on save i believe, but i do that
            --  via the conform plugin. Neet to figure out which is the best way
            --  to do things
            if client.supports_method('textDocument/formatting') then
              vim.api.nvim_create_autocmd('BufWritePre', {
                buffer = args.buf,
                callback = function()
                  --vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                end,
              })
            end
          end,
        })
      end,
    },
    { "williamboman/mason-lspconfig.nvim" },
    --    { "hrsh7th/nvim-cmp" },
  },
  config = function()
    local lsp = require("lsp-zero")

    require("mason").setup({})
    require("mason-lspconfig").setup({
      ensure_installed = {
        "clangd",
        "ts_ls",
        "eslint",
        "html",
        "angularls",
        "helm_ls",
        "lua_ls",
        "jsonls",
        "html",
        "pylsp",
        "dockerls",
        "bashls",
--        "gopls",
        "tflint",
      },
      handlers = {
        lsp.default_setup,
        -- lua_ls = function()
        --   local lua_opts = lsp.nvim_lua_ls()
        --   require("lspconfig").lua_ls.setup(lua_opts)
        -- end,
        jdtls = function()
          -- Skip jdtls setup here, handled by nvim-jdtls plugin
        end,
      },
    })
  end,

}
