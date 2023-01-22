function _G.show_signs()
  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local line2texts = get_signs()
  local buf = vim.api.nvim_create_buf(false, true)

  -- TODO remove the last line
  -- TODO add current line sign
  for l = 1, win_height do
    local text = line2texts[l]
    vim.api.nvim_buf_set_lines(buf, l - 1, -1, true, { text == nil and "" or text, "" })
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
  vim.api.nvim_open_win(buf, false, opts)
end

function _G.get_signs()
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
          l = math.ceil(l * win_height / buf_height)
        end
        -- NOTE several signs may be assigned to the same key
        res[l] = def.text
        break
      end
    end
  end
  return res
end
