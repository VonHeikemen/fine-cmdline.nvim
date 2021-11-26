local M = {fn = {}}
local fn = {}

local Input = require('nui.input')
local event = require('nui.utils.autocmd').event

local state = {
  query = '',
  history = nil,
  idx_hist = 0,
  hooks = {},
  cmdline = {},
  user_opts = {}
}

local defaults = {
  cmdline = {
    enable_keymaps = true,
    smart_history = false
  },
  popup = {
    position = {
      row = '10%',
      col = '50%',
    },
    size = {
      width = '60%',
      height = 1
    },
    border = {
      style = 'rounded',
      highlight = 'FloatBorder',
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  },
  hooks = {
    before_mount = function() end,
    after_mount = function() end,
    set_keymaps = function() end
  }
}

M.input = nil
M.setup = function(config)
  config = config or {}
  state.user_opts = config

  local popup_options = fn.merge(defaults.popup, config.popup)
  state.hooks = fn.merge(defaults.hooks, config.hooks)
  state.cmdline = fn.merge(defaults.cmdline, config.cmdline)

  M.input = Input(popup_options, {
    prompt = ': ',
    default_value = '',
    on_submit = function(value)
      fn.reset_history()
      vim.fn.histadd('cmd', value)
      vim.cmd(value)
    end,
    on_close = function()
      fn.reset_history()
    end,
    on_change = fn.on_change()
  })
end

M.open = function()
  M.setup(state.user_opts)
  state.hooks.before_mount(M.input)

  M.input:mount()

  if state.cmdline.enable_keymaps then
    fn.keymaps()
  end

  fn.map('<BS>', function()
    fn.prompt_backspace(M.input.input_props.prompt:len())
  end)

  state.hooks.set_keymaps(fn.map, fn.feedkeys)
  state.hooks.after_mount(M.input)
end

fn.on_change = function()
  local prev_hist_idx = 0
  return function(value)
    if value == '' then return end

    if prev_hist_idx == state.idx_hist then
      state.query = value
      return
    end

    prev_hist_idx = state.idx_hist
  end
end

fn.keymaps = function()
  fn.map('<Esc>', M.fn.close)
  fn.map('<C-c>', M.fn.close)

  fn.map('<Tab>', M.fn.complete_or_next_item)
  fn.map('<S-Tab>', M.fn.previous_item)

  if state.cmdline.smart_history then
    fn.map('<Up>', M.fn.up_search_history)
    fn.map('<Down>', M.fn.down_search_history)
  else
    fn.map('<Up>', M.fn.up_history)
    fn.map('<Down>', M.fn.down_history)
  end
end

M.fn.close = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-e>')
  else
    M.input.input_props.on_close()
  end
end

M.fn.up_search_history = function()
  local prompt = M.input.input_props.prompt:len()
  local line = vim.fn.getline('.')
  local user_input = line:sub(prompt + 1, vim.fn.col('.'))
  local prev_cmd = state.history and state.history[state.idx_hist]

  if (line:len() == prompt) then
    M.fn.up_history()
    return
  end

  fn.cmd_history()
  local idx = state.idx_hist == 0 and 1 or (state.idx_hist + 1)

  while(state.history[idx]) do
    local cmd = state.history[idx]

    if vim.startswith(cmd, state.query) then
      state.idx_hist = idx
      fn.replace_line(cmd)
      return
    end

    idx = idx + 1
  end
end

M.fn.down_search_history = function()
  local prompt = M.input.input_props.prompt:len()
  local line = vim.fn.getline('.')
  local user_input = line:sub(prompt + 1, vim.fn.col('.'))
  local prev_cmd = state.history and state.history[state.idx_hist]

  if (line:len() == prompt) then
    M.fn.down_history()
    return
  end

  fn.cmd_history()
  local idx = state.idx_hist == 0 and #state.history or (state.idx_hist - 1)

  while(state.history[idx]) do
    local cmd = state.history[idx]

    if vim.startswith(cmd, state.query) then
      state.idx_hist = idx
      fn.replace_line(cmd)
      return
    end

    idx = idx - 1
  end
end

M.fn.up_history = function()
  fn.cmd_history()
  state.idx_hist = state.idx_hist + 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.replace_line(cmd)
end

M.fn.down_history = function()
  fn.cmd_history()
  state.idx_hist = state.idx_hist - 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.replace_line(cmd)
end

M.fn.complete_or_next_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-n>')
  else
    fn.feedkeys('<C-x><C-v>')
  end
end

M.fn.next_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-n>')
  end
end

M.fn.previous_item = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-p>')
  end
end

fn.replace_line = function(cmd)
  vim.cmd('normal Vc')
  vim.api.nvim_buf_set_lines(
    M.input.bufnr,
    vim.fn.line('.') - 1,
    vim.fn.line('.'),
    true,
    {M.input.input_props.prompt ..  cmd}
  )

  vim.api.nvim_win_set_cursor(
    M.input.winid,
    {vim.fn.line('$'), vim.fn.getline('.'):len()}
  )
end

fn.cmd_history = function()
  if state.history then return end

  local history_string = vim.fn.execute('history cmd')
  local history_list = vim.split(history_string, '\n')

  local results = {}
  for i = #history_list, 3, -1 do
    local item = history_list[i]
    local _, finish = string.find(item, '%d+ +')
    table.insert(results, string.sub(item, finish + 1))
  end

  state.history = results
end

fn.reset_history = function()
  state.idx_hist = 0
  state.history = nil
  state.query = ''
end

fn.merge = function(defaults, override)
  return vim.tbl_deep_extend(
    'force',
    {},
    defaults,
    override or {}
  )
end

fn.map = function(lhs, rhs)
  if type(rhs) == 'string' then
    local keys = rhs
    rhs = function() fn.feedkeys(keys) end
  end

  M.input:map('i', lhs, rhs, {noremap = true}, true)
end

fn.feedkeys = function(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    'i',
    true
  )
end

-- Default backspace has inconsistent behavior, have to make our own (for now)
-- Taken from here:
-- https://github.com/neovim/neovim/issues/14116#issuecomment-976069244
fn.prompt_backspace = function(prompt)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local col = cursor[2]

  if col ~= prompt then
    vim.api.nvim_buf_set_text(0, line - 1, col - 1, line - 1, col, {''})
    vim.api.nvim_win_set_cursor(0, {line, col - 1})
  end
end

return M

