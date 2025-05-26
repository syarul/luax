local State = {}
State.__index = State

function State:new(input)
  return setmetatable({
    input = input,
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
    doc_type_start_pos = 0,
    var = false,
    var_store = {},
    reset_store = {},
  }, self)
end
function State:inc_deep_node()
  self.deep_node = self.deep_node + 1
  return self
end
function State:dec_deep_node()
  self.deep_node = self.deep_node - 1
  return self
end
function State:inc(v)
  self.pos = (v ~= nil) and self.pos + v or self.pos + 1
  return self
end
function State:conc(val, inc)
  self.output = type(val) == "table" and self.output .. table.concat(val, "") or self.output .. val
  self:inc(inc or 0)
  return self
end
function State:toggle(key, bool)
  if key == nil then return self end
  self[key] = (bool ~= nil and bool) or (bool == nil and not self[key])
  return self
end

-- checkers
function State:get_token()
  return self.input:sub(self.pos, self.pos)
end
function State:is_html(level)
  return self.deep_node > (level or 0)
end
function State:not_str()
  return not self.deep_string and not self.deep_string_apos and not self.script_node and not self.style_node
end
function State:opening_tag()
  return self:get_token() == "<" and self:not_str()
end
function State:opening_tag_with(param)
  local node = (param == 'script') and 'style' or 'script'
  return self:get_token() == "<" and not self[node .. '_node'] and not self:not_str()
    and self.input:match("</([%w-]+)>", self.pos) == param
end
function State:string_node(string)
  return self:get_token() == string and self:is_html() and not self.script_node
end
function State:closing_tag(string)
  return self:get_token() == string and self:is_html() and self:not_str()
end
function State:forward_slash_tag()
  return self:get_token() == "/" and self.input:sub(self.pos + 1, self.pos + 1) == ">" and self:not_str()
end
function State:closing_bracket()
  return self:get_token() == "}" and self.var and self:not_str()
end

return State
