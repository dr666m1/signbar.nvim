local Set = require("signbar.set")
local utils = require("signbar.utils")
local M = {}

function M.refresh()
  local signs = M.get_signs()

  -- you can close signbar window but don't delete buffer using `:bd`!
  M.open_buf_if_not_exists()

  -- autocmd is needed for syntax highlight to take effect immediately
  local group = vim.api.nvim_create_augroup("signbar_syntax", {})
  local lines = {}
  local win_height = vim.o.lines - vim.o.cmdheight - 1 -- -1 is statusline

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
        vim.api.nvim_exec(
          syn_cmd,
          false -- do not capture output
        )
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

  if M.win and utils.resized() then
    vim.api.nvim_win_close(
      M.win,
      true -- force
    )
  end

  M.open_win_if_not_exists()

  local cmd = string.format("call setpos('.', [0, %d, 1, 0])", utils.adjust_idx(vim.fn.line(".")))
  vim.fn.win_execute(M.win, cmd)
  vim.api.nvim_buf_set_option(M.buf, "filetype", "signbar")
end

function M.get_signs()
  local definitions = {}
  for _, d in ipairs(vim.fn.sign_getdefined()) do
    definitions[d.name] = { text = d.text, texthl = d.texthl }
  end

  local signs = vim.fn.sign_getplaced(
    vim.fn.bufname(), -- current buffer
    {
      group = "*", -- all group
    }
  )[1].signs

  local res = {}
  for _, sign in pairs(signs) do
    if M.ignored_sign_names:contains(sign.name) then
      goto continue
    end
    if M.ignored_sign_groups:contains(sign.group) then
      goto continue
    end
    -- several signs may be assigned to the same key
    res[utils.adjust_idx(sign.lnum)] = { text = definitions[sign.name].text, hl = definitions[sign.name].texthl }
    ::continue::
  end
  return res
end

function M.open_buf_if_not_exists()
  if M.buf then
    return
  end

  M.buf = vim.api.nvim_create_buf(
    false, -- nobuflisted
    true -- scratch-buffer
  )
end

function M.open_win_if_not_exists()
  if M.win and #vim.fn.win_findbuf(M.buf) > 0 then
    return
  end

  local opts = {
    relative = "editor",
    width = 2,
    height = vim.o.lines - vim.o.cmdheight - 1,
    anchor = "NE",
    col = vim.o.columns,
    row = 0,
    style = "minimal",
  }
  M.win = vim.api.nvim_open_win(M.buf, false, opts)
  vim.api.nvim_win_set_option(M.win, "wrap", false)
  vim.api.nvim_win_set_option(M.win, "cursorline", true)
end

function M.setup(config)
  config = config or {}
  M.refresh()

  local group = vim.api.nvim_create_augroup("signbar", {})
  if config.refresh_interval == nil then
    vim.api.nvim_create_autocmd({ "CursorMoved" }, { pattern = "*", group = group, callback = M.refresh })
  else
    -- :h lua-loop
    if M.timer ~= nil then -- in the case that M.setup is called multiple times
      M.timer:stop()
    end
    M.timer = vim.loop.new_timer()
    -- NOTE if refresh_interval is too short, you'll see E322
    M.timer:start(1000, config.refresh_interval, vim.schedule_wrap(M.refresh))
  end
  -- to check sign groups or names use ...
  -- :sign place group=*
  M.ignored_sign_names = Set:new(config.ignored_sign_names or {})
  M.ignored_sign_groups = Set:new(config.ignored_sign_groups or {})
end

return M
