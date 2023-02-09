local Set = {}

function Set:new(arr)
  local set = {}
  for _, elm in ipairs(arr) do
    set[elm] = true
  end
  self.__index = self
  return setmetatable(set, self)
end

function Set:contains(elm)
  return self[elm] or false
end

return Set
