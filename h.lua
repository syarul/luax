local void_tags = {
  "area", "base", "basefont", "br", "col",
  "frame", "hr", "img", "input", "link",
  "meta", "param", "embed", "command", "keygen",
  "source", "track", "wbr"
}

local function is_void_tag(tag)
  for _, void_tag in ipairs(void_tags) do
    if void_tag == tag then
      return true
    end
  end
  return false
end

local function kebab_case(tag)
  if not tag:match("^[a-z]") and tag:match("%u%u") and tag:match("[^%w]") then
    return tag
  end
  local kebab = tag:gsub("(%u)", "-%1"):lower()
  return kebab:gsub("^%-", "")
end

local function create_element(tag, atts, children)
  return {
    tag = tag,
    atts = atts or {},
    children = children or {}
  }
end

local function is_atts(tbl, tag)
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
      if type(children[1]) == "table" and is_atts(children[1], tag) and #children ~= 1 then
        atts = children[1]
        children = { select(2, ...) }
      end
      if atts == nil and is_atts(children[1], tag) then
        atts = children[1]
        children = { select(2, children) }
      end
      atts = atts or children[1]
      return create_element(tag, atts, children)
    end
  end
})

local function sanitize_value(str)
    return (str:gsub("[<>&]", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;"
    }))
end

local function h(element)
  if type(element) ~= "table" then return element or "" end
  local tkeys = {}
  -- asume  as nodeList
  if type(element.atts) ~= "table" then
    local node_list = {}
    for _, k in ipairs(element) do
      table.insert(node_list,  h(k) or "")
    end
    return table.concat(node_list)
  end
  for k in pairs(element.atts) do table.insert(tkeys, k) end
  if #tkeys then table.sort(tkeys) end
  local atts = ""
  local children = ""
  for _, k in ipairs(tkeys) do
    local v = element.atts[k]
    if type(v) ~= "table" then
      if k ~= "children" then
        atts = atts .. " " .. k .. "=\"" .. sanitize_value(v) .. "\""
      else
        children = v
      end
    end
  end
  for _, child in ipairs(element.children) do
    if type(child) == "table" then
      children = children .. h(child)
    elseif element.tag == "script" then
      children = children .. child
    else
      children = children .. sanitize_value(child)
    end
  end
  if element.tag:lower() == "doctype" then
    return "<!" .. kebab_case(element.tag:lower()) .. " " .. table.concat(element.atts, " ") .. ">" .. children
  elseif is_void_tag(element.tag) then
    return "<" .. kebab_case(element.tag) .. atts .. ">"
  else
    return "<" .. kebab_case(element.tag) .. atts .. ">" .. children .. "</" .. kebab_case(element.tag) .. ">"
  end
end

return h
