_G.llm = vim.env.NVIM_LLM or 'copilot'

-- Machine-local config (written by install.sh)
pcall(dofile, vim.fn.stdpath("config") .. "/local.lua")

-- disable language provider support (lua and vimscript plugins only)
vim.g.loaded_perl_provider = 0
-- vim.g.loaded_ruby_provider = 0
-- vim.g.loaded_node_provider = 0
vim.g.loaded_python_provider = 0
vim.g.loaded_python3_provider = 0

vim.g.mapleader = ' '

if vim.g.machine == "work" then
  local toolbox = os.getenv('HOME') .. '/.toolbox/bin'
  if not string.find(vim.env.PATH or '', toolbox, 1, true) then
    vim.env.PATH = toolbox .. ':' .. vim.env.PATH
  end
end
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true
-- vim.opt.shiftwidth = 4

vim.opt.number = true
vim.opt.relativenumber = true
-- Enable mouse mode
vim.opt.mouse = 'a'

-- Sync with OS clipboard
vim.opt.clipboard = 'unnamedplus'

-- Ensure wrapped lines continue with same indent as start of line
vim.opt.breakindent = true

-- Save undo histore
vim.opt.undofile = true

-- Case-insensative searching UNLESS \C or one or more capital letters in search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- The gutter column to the left of numbers where warnings are shown
vim.opt.signcolumn = 'yes'

-- If nothing is typed for this time, the .swap file will be written to disc
vim.opt.updatetime = 750

-- Time to wait for mapped sequence to complete
vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Configure how whitespace characters are displayed
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimum number of lines below and above the cursor
vim.opt.scrolloff = 10

--
-- Simplify navigating between spli panes
-- Ctrl-h/j/k/l now handled by vim-tmux-navigator plugin

vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<leader><leader>s", "<cmd>source $MYVIMRC<CR>", { desc = "Source nvim config" })

if vim.g.machine == "work" then
  -- Brazil build + LSP restart
  vim.keymap.set("n", "<leader>bb", function()
    local root = vim.fn.findfile("packageInfo", ".;")
    local cmd
    if root ~= "" then
      local pkg_dir = vim.fn.fnamemodify(root, ":h")
      local ws_root = vim.fn.fnamemodify(pkg_dir, ":h")
      local siblings = vim.fn.glob(ws_root .. "/*/Config", false, true)
      if #siblings > 1 then
        cmd = "cd " .. ws_root .. " && brazil-recursive-cmd --allPackages brazil-build build"
      else
        cmd = "cd " .. pkg_dir .. " && brazil-build build"
      end
    else
      cmd = "brazil-build build"
    end
    vim.notify("Building: " .. cmd, vim.log.levels.INFO)
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code == 0 then
          vim.schedule(function()
            vim.notify("Build succeeded, restarting LSP", vim.log.levels.INFO)
            vim.cmd("LspRestart")
          end)
        else
          vim.schedule(function()
            vim.notify("Build failed (exit " .. code .. ")", vim.log.levels.ERROR)
          end)
        end
      end,
    })
  end, { desc = "Brazil build + LSP restart" })
end
vim.keymap.set("n", "<leader>x", ":.lua<CR>")
vim.keymap.set("v", "<leader>x", ":lua<CR>")

vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>")

-- Diagnostic navigation
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Diagnostic float" })
vim.keymap.set("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

vim.keymap.set("n", "<leader>nt", "<cmd>tabnew<CR>", { desc = 'Open new tab' })
vim.keymap.set("n", "<leader>ct", "<cmd>tabclose<CR>", { desc = 'Open new tab' })

-- vim.keymap.set("n", "<C-S-h>", "gT", { desc = "Move left one tab" })
-- vim.keymap.set("n", "<C-S-l>", "gt", { desc = "Move right one tab" })
vim.keymap.set("n", "gb", "gT", { desc = "Move left one tab" })
-- vim.keymap.set("n", "<M-l>", "gt", { desc = "Move right one tab" })

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

require("config.lazy")
require("config.lsp-commands").setup()
vim.cmd [[colorscheme tokyonight-night]]

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

local job_id = 0
vim.keymap.set("n", "<space>st", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 15)

  job_id = vim.bo.channel
end)

-- This takes the channel id set above and runs this command in it
--  This could be used for automating run commands such as make or go run or go test
vim.keymap.set("n", "<space>example", function()
  vim.fn.chansend(job_id, { "ls -al\r\n" })
end)

--require("obsidian")
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end)
