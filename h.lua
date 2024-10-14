local voidTags = {
  "area", "base", "basefont", "br", "col",
  "frame", "hr", "img", "input", "link",
  "meta", "param", "embed", "command", "keygen",
  "source", "track", "wbr"
}

local function isVoidTag(tag)
  for _, voidTag in ipairs(voidTags) do
    if voidTag == tag then
      return true
    end
  end
  return false
end

local function kebabCase(tag)
  if not tag:match("^[a-z]") and tag:match("%u%u") and tag:match("[^%w]") then
    return tag
  end
  local kebab = tag:gsub("(%u)", "-%1"):lower()
  return kebab:gsub("^%-", "")
end

local function createElement(tag, atts, children)
  return {
    tag = tag,
    atts = atts or {},
    children = children or {}
  }
end

local function isAtts(tbl, tag)
  if tag:lower() == "doctype" then
    return true
  end
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
      if type(children[1]) == "table" and isAtts(children[1], tag) and #children ~= 1 then
        atts = children[1]
        children = { select(2, ...) }
      end
      if atts == nil and isAtts(children[1], tag) then
        atts = children[1]
        children = { select(2, children) }
      end
      atts = atts or children[1]
      return createElement(tag, atts, children)
    end
  end
})

local function h(element)
  if type(element) ~= "table" then return element or "" end
  local tkeys = {}
  for k in pairs(element.atts) do table.insert(tkeys, k) end
  if #tkeys then table.sort(tkeys) end
  local atts = ""
  local children = ""
  for _, k in ipairs(tkeys) do
    local v = element.atts[k]
    if type(v) ~= "table" then
      if k ~= "children" then
        atts = atts .. " " .. k .. "=\"" .. v .. "\""
      else
        children = v
      end
    end
  end
  for _, child in ipairs(element.children) do
    if type(child) == "table" then
      children = children .. h(child)
    else
      children = children .. child
    end
  end
  if element.tag:lower() == "doctype" then
    return "<!" .. kebabCase(element.tag:lower()) .. " " .. table.concat(element.atts, " ") .. ">" .. children
  elseif isVoidTag(element.tag) then
    return "<" .. kebabCase(element.tag) .. atts .. ">"
  else
    return "<" .. kebabCase(element.tag) .. atts .. ">" .. children .. "</" .. kebabCase(element.tag) .. ">"
  end
end

return h
