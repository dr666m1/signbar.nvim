local M = {}

function M.show_signs()
  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local signs = M.get_signs()

  -- you can close signbar window but don't delete buffer using `:bd`!
  if M.buf == nil then
    M.buf = vim.api.nvim_create_buf(
      false, -- nobuflisted
      true -- scratch-buffer
    )
  end

  -- autocmd is needed for syntax highlight to take effect immediately
  local group = vim.api.nvim_create_augroup("signbar_syntax", {})

  local lines = {}
  for l = 1, win_height do
    local sign = signs[l]
    if sign == nil then
      table.insert(lines, "")
      goto continue
    end

    if sign.hl == nil then
      table.insert(lines, sign.text)
      goto continue
    end

    -- sign.hl is appended here to distinguish signs that have the same text
    table.insert(lines, sign.text .. sign.hl)

    local syn_group = "Signbar" .. sign.hl
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "signbar",
      group = group,
      callback = function()
        local syn_cmd = string.format(
          'syntax match %s "\\v^%s%s$"',
          syn_group,
          -- add characters to escape when something went wrong
          vim.fn.escape(sign.text, "~[("),
          sign.hl
        )
        vim.api.nvim_exec(syn_cmd, false)
        local hl_cmd = string.format("highlight link %s %s", syn_group, sign.hl)
        vim.api.nvim_exec(hl_cmd, false)
      end,
    })
    ::continue::
  end
  vim.api.nvim_buf_set_lines(
    M.buf,
    0, -- start
    -1, -- end (lenth + 1 - 1)
    true, -- out-of-bound shoud be an error
    lines
  )

  local opts = {
    relative = "editor",
    width = 2,
    height = vim.o.lines - vim.o.cmdheight - 1,
    anchor = "NE",
    col = vim.o.columns,
    row = 0,
    style = "minimal",
  }
  if M.win == nil or #vim.fn.win_findbuf(M.buf) == 0 then
    M.win = vim.api.nvim_open_win(M.buf, false, opts)
    vim.api.nvim_win_set_option(M.win, "wrap", false)
    vim.api.nvim_win_set_option(M.win, "cursorline", true)
  end

  -- TODO sometimes M.adjust_height is not needed
  local cmd = string.format("call setpos('.', [0, %d, 1, 0])", M.adjust_height(vim.fn.line(".")))
  vim.fn.win_execute(M.win, cmd)
  vim.api.nvim_buf_set_option(M.buf, "filetype", "signbar")
end

function M.get_signs()
  local definitions = vim.fn.sign_getdefined()
  local signs = vim.fn.sign_getplaced(
    vim.fn.bufname(), -- current buffer
    {
      group = "*", -- all group
    }
  )[1].signs

  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local buf_height = vim.fn.line("$")
  local exceed = buf_height > win_height

  local res = {}
  for _, sign in pairs(signs) do
    for _, def in pairs(definitions) do
      if def.name == sign.name then
        local l = sign.lnum
        if exceed then
          l = M.adjust_height(l)
        end
        -- several signs may be assigned to the same key
        res[l] = { text = def.text, hl = def.texthl }
        break
      end
    end
  end
  return res
end

function M.adjust_height(line)
  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local buf_height = vim.fn.line("$")
  return math.ceil(line * win_height / buf_height)
end

function M.setup(config)
  config = config or {}

  local group = vim.api.nvim_create_augroup("signbar", {})
  if config.refresh_interval == nil then
    vim.api.nvim_create_autocmd({ "CursorMoved" }, { pattern = "*", group = group, callback = M.show_signs })
  else
    -- :h lua-loop
    if M.timer ~= nil then -- in the case that M.setup is called multiple times
      M.timer:stop()
    end
    M.timer = vim.loop.new_timer()
    M.timer:start(0, config.refresh_interval, vim.schedule_wrap(M.show_signs))
  end
  vim.api.nvim_create_autocmd({ "WinScrolled" }, {
    pattern = "*",
    group = group,
    callback = function()
      vim.api.nvim_win_close(
        M.win,
        true -- force
      )
      M.show_signs()
    end,
  })
  -- TODO enable ignore specific sign

  M.show_signs()
end

return M
