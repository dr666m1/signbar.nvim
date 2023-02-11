local Utils = {}

local prev_size = vim.o.lines

function Utils.resized()
  local curr_size = vim.o.lines
  if prev_size == curr_size then
    return false
  end

  prev_size = curr_size
  return true
end

function Utils.adjust_idx(idx)
  local win_height = vim.o.lines - vim.o.cmdheight - 1
  local buf_height = vim.fn.line("$")
  local exceed = buf_height > win_height

  if not exceed then
    return idx
  end

  return math.ceil(idx * win_height / buf_height)
end

return Utils
