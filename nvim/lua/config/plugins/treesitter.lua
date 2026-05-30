return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      -- 1. Setup minimal installation paths
      require("nvim-treesitter").setup()

      -- 2. Explicitly install what you need
      if vim.g.machine == "server" then
        require("nvim-treesitter").install({ "bash", "lua" })
      else
        require("nvim-treesitter").install({
          "go", "java", "python", "json" -- Core ones like lua/c/markdown are built-in
        })
      end

      -- 3. Built-in Keymaps
      -- Neovim 0.12 has native [n, ]n, an, in for selection; 
      -- you don't actually need to map them anymore.
    end

		--   config = function()
		--     -- 1. Setup the plugin (minimal setup required now)
		--     require("nvim-treesitter").setup()
		--
		--     -- 2. Replacement for ensure_installed
		--     local ensure_installed = {
		--  "c",
		--  "lua",
		--  "go",
		--  "java",
		--  "vim",
		--  "vimdoc",
		--  "query",
		--  "markdown",
		--  "markdown_inline"
		--     }
		--     -- This only installs parsers if they are missing
		--     require("nvim-treesitter").install(ensure_installed)
		--
		--     -- 3. Enabling Highlighting (The modern way)
		--     vim.api.nvim_create_autocmd("FileType", {
		--  callback = function(args)
		--      local bufnr = args.buf
		--      local ft = vim.bo[bufnr].filetype
		--
		--      local ignore_ft = {
		-- "oil",
		-- "TelescopePrompt",
		-- "TelescopeResults",
		-- "help",
		-- "blink-cmp-menu",
		-- "blink-cmp-signature",
		-- "fidget",
		-- "lazy_backdrop",
		-- "lazy",
		-- ""
		--      }
		--
		--      if vim.tbl_contains(ignore_ft, ft) then
		-- return
		--      end
		--
		--      local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
		--      local has_parser = lang and pcall(vim.treesitter.get_parser, bufnr, lang)
		--
		--      if has_parser then
		-- local max_filesize = 100 * 1024 -- 100 KB
		-- local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
		--
		-- if lang and (not ok or not stats or stats.size <= max_filesize) then
		--     vim.treesitter.start(bufnr, lang)
		-- end
		--      end
		--  end,
		--     })
		--
		--     -- 4. Selection (Mapping to the NEW Neovim core built-ins)
		--     -- init_selection/node_incremental is now mostly replaced by:
		--     vim.keymap.set({ "x", "o" }, "in", function() require'vim.treesitter._select'.select_child() end)
		--     vim.keymap.set({ "x", "o" }, "an", function() require'vim.treesitter._select'.select_parent() end)
		--   end,
  },
}
