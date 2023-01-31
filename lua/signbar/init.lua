-- TODO refactor using string.format()
local M = {}

function M.show_signs()
  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local signs = M.get_signs()

  -- NOTE you can close signbar window but don't delete buffer using `:bd`!
  if M.buf == nil then
    M.buf = vim.api.nvim_create_buf(
      false, -- nobuflisted
      true -- scratch-buffer
    )
  end

  -- NOTE autocmd is needed for syntax highlight to take effect immediately
  local group = vim.api.nvim_create_augroup("signbar_syntax", {})
  -- TODO remove the last line
  for l = 1, win_height do
    local sign = signs[l]
    if sign == nil then
      vim.api.nvim_buf_set_lines(M.buf, l - 1, -1, true, { "", "" })
    else
      vim.api.nvim_buf_set_lines(M.buf, l - 1, -1, true, { sign.text .. sign.hl, "" })
      local syn_group = "Signbar" .. sign.hl
      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = "signbar",
        group = group,
        callback = function()
          -- TODO handle regex special character
          vim.api.nvim_exec("syntax match " .. syn_group .. ' "\\v^' .. sign.text .. sign.hl .. '$"', false)
          vim.api.nvim_exec("highlight link " .. syn_group .. " " .. sign.hl, false)
        end,
      })
    end
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
  if M.win == nil or #vim.fn.win_findbuf(M.buf) == 0 then
    M.win = vim.api.nvim_open_win(M.buf, false, opts)
    vim.api.nvim_win_set_option(M.win, "wrap", false)
    vim.api.nvim_win_set_option(M.win, "cursorline", true)
  end

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
        -- NOTE several signs may be assigned to the same key
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

function M.setup()
  local group = vim.api.nvim_create_augroup("signbar", {})
  vim.api.nvim_create_autocmd(
    -- TODO enable to change event
    { "BufWritePost" },
    { pattern = "*", group = group, callback = M.show_signs }
  )
  -- TODO enable ignore specific sign
end

return M
