local utils = require('helper/util')
local format_doc_type_params = utils.format_doc_type_params
local kebab_to_camel = utils.kebab_to_camel
local reset_table = utils.reset_table
local table_handler = utils.table_handler
local table_handler_with_handle = utils.table_handler_with_handle
local trail = utils.trail
local get_trail_from_input = utils.get_trail_from_input
local get_trail_from_output = utils.get_trail_from_output
local next_keyword = utils.next_keyword

local _M = {}

local function get_tag_name(s, re)
  local next_spacing_pos = s.input:find("%s", s.pos) or s.input:find("%>", s.pos)
  local tag_range = s.input:sub(s.pos, next_spacing_pos)
  return tag_range:match(re, 0)
end

local function handle_tag_doc_type(s, tag_name, tag_doc_type)
  if tag_doc_type then
    tag_name = tag_doc_type:sub(2)
    s.doc_type = true
    s.doc_type_start_pos = s.pos + #tag_doc_type + 2
    s:inc()
  end
  return tag_name
end

local function check_tag_name(s, tag_name)
  local tag, count = kebab_to_camel(tag_name)
  s:inc(count)
  return tag
end

local function handle_tag_name(s, tag_name)
  if tag_name then
    tag_name = (tag_name:match("(%-+)") and check_tag_name(s, tag_name)) or tag_name
    s:inc_deep_node()
  end
  return tag_name
end

local function handle_tag_name_not_deep_string(s, tag_name, tag_script, tag_style)
  s:toggle("is_tag", true):toggle("text_node", false)
  local tag_name_not_string_handlers = {
    {
      check = s.text_node_start,
      handler = function ()
        s:toggle("text_node_start"):conc("]]")
      end
    },
    {
      check = tag_script,
      params = { "script_node_init" }
    },
    {
      check = tag_style,
      params = { "style_node_init" }
    }
  }
  table_handler(tag_name_not_string_handlers, function(param)
    s[param] = not s[param]
  end)
  local tag_name_is_html_handlers = {
    {
      check = s:is_html(1) and next_keyword(s) == "return",
      params = {{ tag_name, "({" }},
    },
    {
      check = s:is_html(1) and next_keyword(s) ~= "return",
      params = {{", ", tag_name, "({"}},
    },
    {
      check = true,
      params = {{tag_name, "({"}},
    }
  }
  table_handler_with_handle(tag_name_is_html_handlers, function (...)
    s:conc(...)
  end)
  s:inc(#tag_name)
end

local function  handle_tag_name_end(s, tag_name_end)
  if tag_name_end:match("(%-+)") then
    local tag, count = kebab_to_camel(tag_name_end)
    tag_name_end = tag
    s:inc(count)
  end
  s:dec_deep_node()

  local tag_name_end_handlers = {
    {
      check = s.is_tag and not s.text_node and get_trail_from_input(s):sub(#get_trail_from_input(s) - 1, #get_trail_from_input(s) - 1) == "/",
      params = {"is_tag", {")"}}
    },
    {
      check = s.is_tag and not s.text_node and get_trail_from_input(s):sub(#get_trail_from_input(s) - 1, #get_trail_from_input(s) - 1) ~= "/",
      params = {"is_tag", {"})"}}
    },
    {
      check = s.is_tag and s.text_node,
      params = {nil, {"]])"}}
    },
    {
      check = s.text_node_start,
      params = {"text_node_start", {"]])"}}
    },
    {
      check = true,
      params = {nil, {")"}}
    }
  }
  table_handler_with_handle(tag_name_end_handlers, function (toggler, closing_tag)
    s:toggle(toggler):conc(closing_tag)
  end)
  s:inc(#tag_name_end + 2)
end

function _M.handle_opening_tag(s)
  local tag_name = get_tag_name(s, "<([%w-]+)")
  local tag_name_end = get_tag_name(s, "</([%w-]+)>")
  local tag_doc_type = get_tag_name(s, "<(%!%w+)")
  local tag_script = tag_name and tag_name:match("script", 0) or tag_name_end and tag_name_end:match("script", 0)
  local tag_style = tag_name and tag_name:match("style", 0) or tag_name_end and tag_name_end:match("style", 0)

  local handlers = {
    handle_tag_doc_type,
    handle_tag_name,
  }

  for _, handle in pairs(handlers) do
    tag_name = handle(s, tag_name, tag_doc_type)
  end

  s:inc()

  local tag_name_handlers = {
    {
      check = tag_name and not s.deep_string,
      params = { s, tag_name, tag_script, tag_style },
      handler = handle_tag_name_not_deep_string
    },
    {
      check = tag_name_end,
      params = { s, tag_name_end },
      handler = handle_tag_name_end
    },
    {
      check = true,
      handler = function ()
        s:conc(s:get_token(), 1)
      end
    }
  }
  table_handler_with_handle(tag_name_handlers)
end

function _M.handle_opening_tag_script(s)
  s:toggle("script_node"):conc("]]")
end

function _M.handle_opening_tag_style(s)
  s:toggle("style_node"):conc("]]")
end

function _M.handle_closing_tag(s)
  local handlers = {
    {
      check = not s.style_node_init
        and not s.script_node_init
        and not s.text_node
        and s.is_tag
        and s.input:sub(s.pos - 1, s.pos - 1) ~= "/",
      handler = function ()
        s:toggle("is_tag"):toggle("text_node"):conc("}")
      end
    },
    {
      check = s.script_node_init,
      params = { "script" }
    },
    {
      check = s.style_node_init and not s.script_node_init,
      params = { "style" }
    },
    {
      check = true,
      handler = function ()
        s.is_tag = not s.is_tag
        s:dec_deep_node():conc("})")
      end
    }
  }
  table_handler_with_handle(handlers, function(param)
    s:toggle(s.is_tag and "is_tag" or nil):toggle(param .. "_node_init")
    local t = get_trail_from_output(s)
    s:toggle(t:sub(#t) == "{" and param .. "_node" or nil):conc(t:sub(#t) == "{" and "}, [[\n" or "}")
  end)
  if s.doc_type then
    s.doc_type = not s.doc_type
    local doc_type_params = s.output:sub(s.doc_type_start_pos, s.pos - 1)
    local output = format_doc_type_params(doc_type_params)
    s.output = s.output:sub(0, s.doc_type_start_pos-1) .. output .. s.output:sub(s.pos)
  end
  s:inc()
end

function _M.handle_opening_bracket(s)
  s.var = not s.var
  if s.var then
    -- snapshot current_state
    reset_table(s.var_store, s)
    -- reset current_state
    reset_table(s, s.reset_store)
  end
  -- local trail = s.input:sub(s.pos - 20, s.pos-1):gsub("[%s\r\n]", "")
  local t = trail(s, "input", s.pos - 20, s.pos-1)
  if t:sub(#t) == ">" or t:sub(#t) == "}" then
    s:conc(", ")
  end
  s:inc()
end

function _M.handle_closing_bracket(s)
  s.var = not s.var
  if not s.var then
    -- restore current_state from snapshot
    reset_table(s, s.var_store)
  end
  s:inc()
end

function _M.handle_xml(s)
  local tok = s:get_token()
  if tok:match("%s")
    and not s.doc_type
    and not s.var
    and s.is_tag
    and s.output:sub(-1) ~= "{"
    and s.output:sub(-1) == "\""
    or
    tok:match("%s")
    and s.is_tag
    and s.input:sub(s.pos - 1, s.pos - 1) == "}"
  then
    s:conc(",")
  end
  if s.text_node
    and not s.text_node_start
    and not s.is_tag
    and not
    (s.input:match("^%s*<(%w+)", s.pos)
    or s.text_node
    and not s.text_node_start
    and s.input:match("^%s*{(%w+)", s.pos))
    and not s.var
  then
    s:toggle("text_node_start"):conc(", [[")
  end
  s:conc(tok, 1)
end

function _M.handle_forward_slash_tag(s)
  s:dec_deep_node()
  s:conc("})")
  s:inc(2)
end

function _M.handle_other(s)
  if not s.text_node and s:not_str() then
    s:toggle("text_node")
    if s.text_node then
      local sub_node = s.input:match("%s*<(%w+)", s.pos)
      local trail = s.input:sub(s.pos - 10, s.pos):gsub("[%s\r\n]", "")
      local handlers = {
        {
          check = s.is_tag and not sub_node and trail:sub(#trail, #trail) ~= ">",
          params = { "}, [[" }
        },
        {
          check = s:is_html() and not sub_node,
          params = { "[[" }
        }
      }
      table_handler(handlers, s.conc)
    end
  end
  s:conc(s:get_token(), 1)
end

function _M.handle_toggle_deep_string(s, string)
  s:toggle(string):conc(s:get_token(), 1)
end

return _M
