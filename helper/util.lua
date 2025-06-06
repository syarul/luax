local _M = {}

function _M.kebab_to_camel(str)
  local tag = str:gsub("%-(%w)", function(c)
    return c:upper()
  end)
  local _, count = str:gsub("-", "-")
  return tag, count
end

local function insert_result(cw, char, result, quote, end_quote)
  if result and cw ~= "" then
    table.insert(result, quote .. cw .. end_quote)
  end
  return result and "" or cw .. char
end

local function get_cw(input, i, in_quotes, cw, result)
  local char = input:sub(i, i)
  local handled = false
  local handlers = {
    { check = char == '"', params = {cw, char, result, '"\\"', '\\""'}, toggle_quotes = true },
    { check = char == ' ' and not in_quotes, params = {cw, char, result, '"', '"'} },
    { check = true, params = {cw, char} },
  }
  for _, handler in pairs(handlers) do
    if not handled and handler.check then
      in_quotes = (handler.toggle_quotes and not in_quotes) or (not handler.toggle_quotes and in_quotes)
      cw = insert_result(table.unpack(handler.params))
      handled = true
    end
  end
  return {cw, in_quotes, result}
end

local function process(input)
  local result = {}
  local cw = ""
  local in_quotes = false
  for i = 1, #input do
    cw, in_quotes, result = table.unpack(get_cw(input, i, in_quotes, cw, result))
  end
  return {cw, result}
end

function _M.format_doc_type_params(input)
  local cw, result = table.unpack(process(input))
  if cw ~= "" then
    table.insert(result, '"' .. cw .. '"')
  end
  return table.concat(result, ', ')
end

function _M.normalize_table_keys(code)
  return code:gsub("{(.-)}", function(block)
      local attr_block = block:gsub("([%w%-_]+)%=([^%s]+)", function (attr, value)
        return (attr:match("[-_]") and '["' .. attr .. '"]=' .. value) or attr .. "=" .. value
      end)
      return "{" .. attr_block .. "}"
  end)
end

-- ignore keys
local ignore_keys = {
  output = true,
  pos = true,
  doc_type = true,
  var = true
}

function _M.reset_table(store, data)
  for key, value in pairs(data) do
    if not ignore_keys[key] then
      store[key] = value
    end
  end
end

function _M.table_handler(handlers, custom_handler)
  local result
  for _, h in ipairs(handlers) do
    if h.check then
      local handler = h.handler or custom_handler
      result = handler(table.unpack(h.params or {}))
    end
  end
  return result
end

function _M.table_handler_with_handle(handlers, custom_handler)
  local handled = false
  for _, h in ipairs(handlers) do
    if not handled and h.check then
      local handler = h.handler or custom_handler
      handler(table.unpack(h.params or {}))
      handled = true
    end
  end
end

function _M.trail(s, key, first, last)
  return s[key]:sub(first, last):gsub("[%s\r\n]", "")
end

function _M.get_trail_from_input(s)
  return _M.trail(s, "input", 0, s.pos - 2)
end

function _M.get_trail_from_output(s)
  return _M.trail(s, "output", #s.output - 10, #s.output)
end

function _M.next_keyword(s)
  return _M.trail(s, "input", s.pos-8, s.pos):sub(0, 6)
end

return _M
