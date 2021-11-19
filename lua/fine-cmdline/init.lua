local M = {fn = {}}
local fn = {}

local Input = require('nui.input')
local event = require('nui.utils.autocmd').event

local state = {
  history = nil,
  idx_hist = 0,
  hooks = {}
}

local defaults = {
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

  local popup_options = fn.merge(defaults.popup, config.popup)
  state.hooks = fn.merge(defaults.hooks, config.hooks)

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
  })
end

M.open = function()
  if not M.input then M.setup({}) end

  state.hooks.before_mount(M.input)

  M.input:mount()
  fn.keymaps()

  state.hooks.set_keymaps(fn.map, fn.feedkeys)
  state.hooks.after_mount(M.input)
end

fn.keymaps = function()
  fn.map('<Esc>', M.fn.close)
  fn.map('<C-c>', M.fn.close)
  fn.map('<Tab>', M.fn.complete_or_next_item)
  fn.map('<S-Tab>', M.fn.previous_item)

  fn.map('<Up>', M.fn.up_history)
  fn.map('<Down>', M.fn.down_history)
end

M.fn.close = function()
  if vim.fn.pumvisible() == 1 then
    fn.feedkeys('<C-e>')
  else
    M.input.input_props.on_close()
  end
end

M.fn.up_history = function()
  fn.cmd_history()
  vim.cmd('normal Vd')
  state.idx_hist = state.idx_hist + 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.feedkeys(cmd)
end

M.fn.down_history = function()
  fn.cmd_history()
  vim.cmd('normal Vd')
  state.idx_hist = state.idx_hist - 1
  local cmd = state.history[state.idx_hist]

  if not cmd then
    state.idx_hist = 0
    return
  end

  fn.feedkeys(cmd)
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

  M.input:map('i', lhs, rhs, {noremap = true})
end

fn.feedkeys = function(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    'i',
    true
  )
end

return M

