-- inspired by https://bvisness.me/luax/
-- a React createElement/hyperscript shallow implementation in LUA
-- usage
-- local myElement = div(
--  { class = "container" },
--  p({ class = "title" }, "Hello, world!"),
--  span({ style = "color: red;" }, "This is a span")
-- )

-- print(h(myElement))

local function createElement(tag, atts, children)
  return {
    tag = tag,
    atts = atts or {},
    children = children or {}
  }
end

local function flattenChildren(children)
  local flattened = {}
  for _, child in ipairs(children) do
    if type(child) == "table" and child.isArray then
      for _, subChild in ipairs(child) do
        table.insert(flattened, subChild)
      end
    else
      table.insert(flattened, child)
    end
  end
  return flattened
end

local function isAtts(tbl)
  for k, v in pairs(tbl) do
    if type(k) ~= "string" or type(v) == "table" then
      return false
    end
  end
  return true
end

setmetatable(_G, {
  __index = function(_, tag)
    return function(...)
      local atts
      local children = { ... }
      if type(children[1]) == "table" and isAtts(children[1]) and #children ~= 1 then
        atts = children[1]
        children = { select(2, ...) }
      end
      children = flattenChildren(children)
      return createElement(tag, atts, children)
    end
  end
})

local function h(element)
  local tkeys = {}
  for k in pairs(element.atts) do table.insert(tkeys, k) end
  table.sort(tkeys)
  local atts = ""
  for _, k in ipairs(tkeys) do
    local v = element.atts[k]
    if type(v) ~= "table" then
      atts = atts .. " " .. k .. "=\"" .. v .. "\""
    end
  end
  local children = ""
  for _, child in ipairs(element.children) do
    if type(child) == "table" then
      children = children .. h(child)
    else
      children = children .. child
    end
  end
  return "<" .. element.tag .. atts .. ">" .. children .. "</" .. element.tag .. ">"
end

return h
