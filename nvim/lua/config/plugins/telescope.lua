return {
  {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.1.9',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    config = function()
      require('telescope').setup {
        defaults = {
          dynamic_preview_title = true,
        },
        pickers = {
          find_files = {
            theme = "ivy",
            path_display = { "filename_first" },
          }
        },
        extensions = {
          fzf = {}
        }
      }

      require('telescope').load_extension('fzf')

      vim.keymap.set("n", "<space>fh", require('telescope.builtin').help_tags)
      vim.keymap.set("n", "<space>fd", require('telescope.builtin').find_files)
      vim.keymap.set("n", "<space>fl", require('telescope.builtin').live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<space>fb", require('telescope.builtin').buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<space>fs", require('telescope.builtin').lsp_document_symbols, { desc = "Document symbols" })
      vim.keymap.set("n", "<space>en", function()
        require('telescope.builtin').find_files {
          cwd = vim.fn.stdpath("config")
        }
      end)
      vim.keymap.set("n", "<space>ep", function()
        require('telescope.builtin').find_files {
          cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
        }
      end)
      require "config.telescope.multigrep".setup()
    end
  }
}
