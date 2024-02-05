local api = vim.api
local cmd = api.nvim_command

local Term = {}
local H = {}

function Term:new()
  return setmetatable({
    win = nil,
    buf = nil,
    terminal = nil,
    config = H.defaults,
  }, { __index = self })
end

function Term:setup(cfg)
  if not cfg then
    return vim.notify('SFTerm: setup() is optional. Please remove it!', vim.log.levels.WARN)
  end

  self.config = vim.tbl_deep_extend('force', self.config, cfg)

  return self
end

function Term:store(win, buf)
  self.win = win
  self.buf = buf

  return self
end

function Term:remember_cursor()
  self.last_win = api.nvim_get_current_win()
  self.prev_win = vim.fn.winnr('#')
  self.last_pos = api.nvim_win_get_cursor(self.last_win)

  return self
end

function Term:restore_cursor()
  if self.last_win and self.last_pos ~= nil then
    if self.prev_win > 0 then
      cmd(('silent! %s wincmd w'):format(self.prev_win))
    end

    if H.is_win_valid(self.last_win) then
      api.nvim_set_current_win(self.last_win)
      api.nvim_win_set_cursor(self.last_win, self.last_pos)
    end

    self.last_win = nil
    self.prev_win = nil
    self.last_pos = nil
  end

  return self
end

function Term:use_existing_or_create_buf()
  local prev = self.buf

  if H.is_buf_valid(prev) then
    return prev
  end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = self.config.ft

  return buf
end

function Term:create_and_open_win(buf)
  local cfg = self.config

  local dim = H.get_dimension(cfg.dimensions)

  local win = api.nvim_open_win(buf, true, {
    border = cfg.border,
    relative = 'editor',
    style = 'minimal',
    title = 'SFTerm',
    title_pos = 'center',
    width = dim.width,
    height = dim.height,
    col = dim.col,
    row = dim.row,
  })

  api.nvim_win_set_option(win, 'winhl', ('Normal:%s'):format(cfg.hl))
  api.nvim_win_set_option(win, 'winblend', cfg.blend)

  return win
end

function Term:handle_exit(job_id, code, ...)
  if self.config.auto_close and code == 0 then
    self:close(true)
  end
  if self.config.on_exit then
    self.config.on_exit(job_id, code, ...)
  end
end

function Term:start_insert()
  cmd('startinsert')
  return self
end

function Term:scroll_to_end()
  cmd('$')
  return self
end

function Term:create_term()
  -- NOTE: `termopen` will fails if the current buffer is modified
  self.terminal = vim.fn.termopen(H.is_cmd(self.config.cmd), {
    clear_env = self.config.clear_env,
    env = self.config.env,
    on_stdout = self.config.on_stdout,
    -- on_stderr = self.config.on_stderr,
    on_exit = function(...)
      self:handle_exit(...)
    end,
  })

  -- This prevents the filetype being changed to `term` instead of `FTerm` when closing the floating window
  api.nvim_buf_set_option(self.buf, 'filetype', self.config.ft)

  return self
end

function Term:open()
  -- Move to existing window if the window already exists
  if H.is_win_valid(self.win) then
    return
  end

  self:remember_cursor()

  local buf = self:use_existing_or_create_buf()
  local win = self:create_and_open_win(buf)

  -- existing buffer already has a terminal opened inside
  if self.buf == buf then
    return self:store(win, buf):scroll_to_end():restore_cursor()
  end

  return self:store(win, buf):create_term():scroll_to_end():restore_cursor()
end

function Term:close(force)
  if not H.is_win_valid(self.win) then
    return self
  end

  api.nvim_win_close(self.win, {})

  self.win = nil

  if force then
    if H.is_buf_valid(self.buf) then
      api.nvim_buf_delete(self.buf, { force = true })
    end

    vim.fn.jobstop(self.terminal)

    self.buf = nil
    self.terminal = nil
  end

  self:restore_cursor()

  return self
end

function Term:toggle()
  -- If window is stored and valid then it is already opened, then close it
  if H.is_win_valid(self.win) then
    self:close()
  else
    self:open()
  end

  return self
end

function Term:run(command)
  self:open()

  api.nvim_chan_send(
    self.terminal,
    command .. '\r'
  )

  return self
end

-- helper -------------------

H.defaults = {
  ft = 'SFTerm',
  cmd = function()
    return assert(
      os.getenv('SHELL'),
      '[SFTerm] $SHELL is not present! Please provide a shell (`config.cmd`) to use.'
    )
  end,
  border = 'single',
  auto_close = true,
  hl = 'Normal',
  blend = 10,
  clear_env = false,
  dimensions = {
    height = 0.4,
    width = 0.8,
    x = 0.5,
    y = 0.9,
  },
  on_stdout = function()
    require("sf.term").open()
  end,
  -- on_stderr = function()
  --   vim.notify('hello stderr', vim.log.levels.ERROR)
  -- end,
}

function H.get_dimension(opts)
  -- get lines and columns
  local cl = vim.o.columns
  local ln = vim.o.lines

  -- calculate our floating window size
  local width = math.ceil(cl * opts.width)
  local height = math.ceil(ln * opts.height - 4)

  -- and its starting position
  local col = math.ceil((cl - width) * opts.x)
  local row = math.ceil((ln - height) * opts.y - 1)

  return {
    width = width,
    height = height,
    col = col,
    row = row,
  }
end

function H.is_win_valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

function H.is_buf_valid(buf)
  return buf and vim.api.nvim_buf_is_loaded(buf)
end

function H.is_cmd(cmd)
  return type(cmd) == 'function' and cmd() or cmd
end

return Term
