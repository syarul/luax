local h = require('h')

local original_require = require

local function reset_table(store, data)
  for key, value in pairs(data) do
    -- ignore output, pos and doctype
    if key ~= "output" and key ~= "pos" and key ~= "doc_type" then
      store[key] = value
    end
  end
end

local State = {}
State.__index = State

function State:new()
  return setmetatable({
    output = "",
    doc_type = nil,
    pos = 1,
    deep_node = 0,
    deep_string = false,
    deep_string_apos = false,
    is_tag = false,
    text_node = false,
    text_node_start = false,
    script_node = false,
    script_node_init = false,
    style_node = false,
    style_node_init = false,
  }, self)
end

function State:inc_deep_node() self.deep_node = self.deep_node + 1 end
function State:dec_deep_node() self.deep_node = self.deep_node - 1 end
function State:inc(v)
  if v ~= nil then self.pos = self.pos + v else self.pos = self.pos + 1 end
end
function State:conc(val, inc)
  if type(val) == "table" then
    self.output = self.output .. table.concat(val, "")
  else
    self.output = self.output .. val
  end
  -- post processing increase token step
  if inc ~= nil then self:inc(inc) end
end
function State:xml(level)
  if level ~= nil then return self.deep_node > level end
  return self.deep_node > 0
end
function State:not_str() return not self.deep_string and not self.deep_string_apos and not self.script_node and not self.style_node end
function State:toggle(key, bool)
  if bool ~= nil then self[key] = bool else self[key] = not self[key] end
end

local function kebab_to_camel(str)
  local tag = str:gsub("%-(%w)", function(c)
      return c:upper()
  end)
  local _, count = str:gsub("-", "-")
  return tag, count
end

local function format_doc_type_params(input)
  local result = {}
  local cw = ""
  local in_quotes = false
  for i = 1, #input do
    local char = input:sub(i, i)
    if char == '"' then
      in_quotes = not in_quotes
      if cw ~= "" then
        table.insert(result, '"\\"' .. cw .. '\\""')
        cw = ""
      end
    elseif char == ' ' and not in_quotes then
      if cw ~= "" then
        table.insert(result, '"' .. cw .. '"')
        cw = ""
      end
    else
      cw = cw .. char
    end
  end
  if cw ~= "" then
    table.insert(result, '"' .. cw .. '"')
  end
  return table.concat(result, ', ')
end

local function normalize_table_keys(code)
  return code:gsub("{(.-)}", function(block)
      local attr_block = block:gsub("([%w%-_]+)%=([^%s]+)", function (attr, value)
        if attr:match("[-_]") then
            return '["' .. attr .. '"]=' ..value
          else
            return attr .. "=" .. value
          end
      end)
      return "{" .. attr_block .. "}"
  end)
end

local function decent_parser_ast(input)
  local var = false
  local s = State:new()
  local reset_store = {}
  reset_table(reset_store, s)
  local var_store = {}
  local doc_type_start_pos = 0

  while s.pos <= #input do
    local tok = input:sub(s.pos, s.pos)
    -- simple decent parser
    -- escape " ' encapsulation
    -- opening tag
    if tok == "<" and s:not_str() then

      local next_spacing_pos = input:find("%s", s.pos) or input:find("%>", s.pos)
      local tag_range = input:sub(s.pos, next_spacing_pos)
      local tag_name = tag_range:match("<([%w-]+)", 0)
      local tag_name_end = tag_range:match("</([%w-]+)>", 0)
      local tag_doc_type = tag_range:match("<(%!%w+)", 0)
      local tag_script = tag_name and tag_name:match("script", 0) or tag_name_end and tag_name_end:match("script", 0)
      local tag_style = tag_name and tag_name:match("style", 0) or tag_name_end and tag_name_end:match("style", 0)
      if tag_doc_type then
        tag_name = tag_doc_type:sub(2)
        s.doc_type = true
        doc_type_start_pos = s.pos + #tag_doc_type + 2
        s:inc()
      end
      if tag_name then
        if tag_name:match("(%-+)") then
          local tag, count = kebab_to_camel(tag_name)
          tag_name = tag
          s:inc(count)
        end
        s:inc_deep_node()
      end
      s:inc()

      if tag_name and not s.deep_string then
        s:toggle("is_tag", true)
        s:toggle("text_node", false)
        if s.text_node_start then
          s:toggle("text_node_start")
          s:conc("]]")
        end
        if tag_script then
          s.script_node_init = not s.script_node_init
        end
        if tag_style then
          s.style_node_init = not s.style_node_init
        end
        if s:xml(1) then
          -- handle internal return function
          local ret = input:sub(s.pos-8, s.pos):gsub("%s\r\n", ""):sub(0, 6) == "return"
          if ret then
            s:conc({tag_name, "({"})
          else
            s:conc({", ", tag_name, "({"})
          end
        else
          s:conc({tag_name, "({"})
        end
        s:inc(#tag_name)
      elseif tag_name_end then
        if tag_name_end:match("(%-+)") then
          local tag, count = kebab_to_camel(tag_name_end)
          tag_name_end = tag
          s:inc(count)
        end
        s:dec_deep_node()
        if s.is_tag and not s.text_node then
          s:toggle("is_tag")
          local trail = input:sub(0, s.pos - 2):gsub("[%s\r\n]", "")
          if trail:sub(#trail - 1, #trail - 1) == "/" then
            s:conc(")")
          else
            s:conc("})")
          end
        elseif s.is_tag and s.text_node then
          s:conc("]])")
        else
          if s.text_node_start then
            s:toggle("text_node_start")
            s:conc("]])")
          else
            s:conc(")")
          end
        end
        s:inc(#tag_name_end + 2)
      else
        s:conc(tok, 1)
      end
    elseif tok == "<" and not s.style_node and not s:not_str() and input:match("</([%w-]+)>", s.pos) == "script" then
      s:toggle("script_node")
      s:conc("]]")
    elseif tok == "<" and not s.script_node and not s:not_str() and input:match("</([%w-]+)>", s.pos) == "style" then
      s:toggle("style_node")
      s:conc("]]")
    elseif tok == '"' and s:xml() and not s.script_node then
      s:toggle("deep_string")
      s:conc(tok, 1)
    elseif tok == "'" and s:xml() and not s.script_node then
      s:toggle("deep_string_apos")
      s:conc(tok, 1)
    elseif tok == ">" and s:xml() and s:not_str() then
      if not s.style_node_init and not s.script_node_init and not s.text_node and s.is_tag and input:sub(s.pos - 1, s.pos - 1) ~= "/" then
        s:toggle("is_tag")
        s:toggle("text_node")
        s:conc("}")
      elseif s.script_node_init then
        if s.is_tag then
          s:toggle("is_tag")
        end
        s:toggle("script_node_init")
        local trail = s.output:sub(#s.output - 10, #s.output):gsub("[%s\r\n]", "")
        if trail:sub(#trail) == "{" then
          s:toggle("script_node")
          s:conc("}, [[\n")
        else
          s:conc("}")
        end
      elseif s.style_node_init and not s.script_node_init then
        if s.is_tag then
          s:toggle("is_tag")
        end
        s:toggle("style_node_init")
        local trail = s.output:sub(#s.output - 10, #s.output):gsub("[%s\r\n]", "")
        if trail:sub(#trail) == "{" then
          s:toggle("style_node")
          s:conc("}, [[\n")
        else
          s:conc("}")
        end
      else
        s.is_tag = not s.is_tag
        s:dec_deep_node()
        s:conc("})")
      end
      if s.doc_type then
        s.doc_type = not s.doc_type
        local doc_type_params = s.output:sub(doc_type_start_pos, s.pos - 1)
        local output = format_doc_type_params(doc_type_params)
        s.output = s.output:sub(0, doc_type_start_pos-1) .. output .. s.output:sub(s.pos)
      end
      s:inc()
    elseif tok == "/" and input:sub(s.pos + 1, s.pos + 1) == ">" and s:not_str() then
      s:dec_deep_node()
      s:conc("})")
      s:inc(2)
    elseif tok == "{" and s:xml() and s:not_str() then
      var = not var
      if var then
        -- snapshot current_state
        reset_table(var_store, s)
        -- reset current_state
        reset_table(s, reset_store)
      end
      local trail = input:sub(s.pos - 20, s.pos-1):gsub("[%s\r\n]", "")
      if trail:sub(#trail) == ">" or trail:sub(#trail) == "}" then
        s:conc(", ")
      end
      s:inc()
    elseif tok == "}" and var and s:not_str() then
      var = not var
      if not var then
        -- restore current_state from snapshot
        reset_table(s, var_store)
      end
      s:inc()
    elseif s:xml() and s:not_str() then
      if tok:match("%s") then
        if not s.doc_type and not var and s.is_tag and s.output:sub(-1) ~= "{" and s.output:sub(-1) == "\"" or
            s.is_tag and input:sub(s.pos - 1, s.pos - 1) == "}" then
          s:conc(",")
        end
      end
      if s.text_node and not s.text_node_start then
        local sub_node = input:match("^%s*<(%w+)", s.pos) or input:match("^%s*{(%w+)", s.pos)
        if not s.is_tag and not sub_node and not var then
          s:toggle("text_node_start")
          s:conc(", [[")
        end
      end
      s:conc(tok, 1)
    else
      if not s.text_node and s:not_str() then
        s:toggle("text_node")
        if s.text_node then
          local sub_node = input:match("%s*<(%w+)", s.pos)
          local trail = input:sub(s.pos - 10, s.pos):gsub("[%s\r\n]", "")
          if s.is_tag and not sub_node then
            if trail:sub(#trail, #trail) ~= ">" then
              s:conc("}, [[")
            end
          elseif s:xml() and not sub_node then
            s:conc("[[")
          end
        end
      end
      s:conc(tok, 1)
    end
  end
  -- this to add [] bracket to table attributes
  s.output = normalize_table_keys(s.output)
  -- encapsulate output if doctype exist
  if s.doc_type ~= nil then s:conc(")") end
  return s.output
end

local function preprocess_lua_file(input_file)
  local input_code = io.open(input_file, "r"):read("*all")
  local transformed_code = decent_parser_ast(input_code)
  -- print("===================")
  -- print(transformed_code)
  -- print("===================")
  return transformed_code
end

function _G.require(module_name)
  local luax_file = module_name:gsub("%.", "/") .. ".luax"
  local lua_file
  local file = io.open(luax_file, "r")
  if file then
    file:close()
    local str = preprocess_lua_file(luax_file)
    -- eval back to buffer file after transform
    lua_file = load(str)()
  else
    return original_require(module_name)
  end
  return lua_file
end

return h
