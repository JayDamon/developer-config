vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("t", "<esc><esc><esc>", "<c-\\><c-n>:q<Enter>")
local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}

-- Function to open a floating window with optional width and height
local function open_floating_window(opts)
  opts = opts or {}
  -- Get the screen dimensions
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  -- Default to 80% of the screen size if not provided in opts
  local width = opts.width or math.floor(screen_width * 0.8)
  local height = opts.height or math.floor(screen_height * 0.8)

  -- Calculate the position to center the window
  local col = math.floor((screen_width - width) / 2)
  local row = math.floor((screen_height - height) / 2)

  -- Create a new buffer
  local buf = nil
  print(opts.buf)
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end
  -- Set the contents of the buffer (just an example)
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "This is a floating window!" })

  -- Define window options
  local win_config = {
    relative = 'editor', -- 'editor' makes the window float relative to the entire editor
    width = width,       -- window width
    height = height,     -- window height
    col = col,           -- left offset from the editor (centered)
    row = row,           -- top offset from the editor (centered)
    style = 'minimal',   -- minimal style, no borders or other decorations
    border = 'rounded',  -- rounded corners for the border
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)
  return { buf = buf, win = win }
end

-- Optionally bind this to a key
-- vim.api.nvim_set_keymap('n', '<Leader>f', ':lua open_floating_window({})<CR>', { noremap = true, silent = true })
local run_c = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    vim.cmd("below split")
    vim.cmd.terminal()
    vim.api.nvim_chan_send(vim.bo.channel, "./run.sh\n")
    vim.api.nvim_feedkeys("a", "t", false)
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

local moneymaker_run = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    vim.cmd("below split")
    vim.cmd.terminal()
    vim.api.nvim_chan_send(vim.bo.channel, "cd ./moneymaker-run\n")
    vim.api.nvim_feedkeys("a", "t", false)
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

local docker_ls = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    vim.cmd("below split")
    vim.cmd.terminal()
    vim.api.nvim_chan_send(vim.bo.channel, "docker ps\n")
    vim.api.nvim_feedkeys("a", "t", false)
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

local standard_term = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    vim.cmd("below split")
    vim.cmd.terminal()
    vim.api.nvim_feedkeys("a", "t", false)
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

-- local buf, win = open_floating_window()
-- print(buf, win)
local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = open_floating_window { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_terminal, {})
vim.keymap.set("n", "<space>ft", toggle_terminal)
vim.keymap.set("n", "<space>tt", toggle_terminal)
vim.keymap.set("n", "<space><space>r", run_c)
vim.keymap.set("n", "<space><space>fc", docker_ls)
vim.keymap.set("n", "<space><space>mr", moneymaker_run)
