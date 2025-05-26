local h = require('h')

local original_require = require

-- util
local utils = require('helper/util')
local normalize_table_keys = utils.normalize_table_keys
local reset_table = utils.reset_table
local table_handler_with_handle = utils.table_handler_with_handle

-- handler
local handlers = require('helper/handler')
local handle_opening_tag = handlers.handle_opening_tag
local handle_opening_tag_script = handlers.handle_opening_tag_script
local handle_opening_tag_style = handlers.handle_opening_tag_style
local handle_closing_tag = handlers.handle_closing_tag
local handle_forward_slash_tag = handlers.handle_forward_slash_tag
local handle_opening_bracket = handlers.handle_opening_bracket
local handle_closing_bracket = handlers.handle_closing_bracket
local handle_xml = handlers.handle_xml
local handle_other = handlers.handle_other
local handle_toggle_deep_string = handlers.handle_toggle_deep_string

local State = require('helper/state')

local function traverse(s)
  while s.pos <= #s.input do
    -- simple decent parser
    local handlers_tree = {
      -- opening tag '<'
      { handler = handle_opening_tag, check = s:opening_tag(), params = { s } },
      -- opening tag with script <script>
      { handler = handle_opening_tag_script, check = s:opening_tag_with("script"), params = { s } },
      -- opening tag with style <style>
      { handler = handle_opening_tag_style, check = s:opening_tag_with("style"), params = { s } },
      -- string node "
      { handler = handle_toggle_deep_string, check = s:string_node('"'), params = { s, "deep_string" } },
      -- string node within string
      { handler = handle_toggle_deep_string, check = s:string_node('"'), params = { s, "deep_string" } },
      -- string node '
      { handler = handle_toggle_deep_string, check = s:string_node("'"), params = { s, "deep_string_apos" } },
      -- closing tag </>
      { handler = handle_closing_tag, check = s:closing_tag(">"), params = { s } },
      -- forward slash tag /
      { handler = handle_forward_slash_tag, check = s:forward_slash_tag(), params = { s } },
      -- opening bracket {
      { handler = handle_opening_bracket, check = s:closing_tag("{"), params = { s } },
      -- closing bracket }
      { handler = handle_closing_bracket, check = s:closing_bracket(), params = { s } },
      -- is_html node
      { handler = handle_xml, check = s:is_html() and s:not_str(), params = { s } },
      -- other node
      { handler = handle_other, check = true, params = { s } },
    }

    table_handler_with_handle(handlers_tree)
  end
end

local function decent_parser_ast(input)
  local s = State:new(input)
  reset_table(s.reset_store, s)

  -- traverse the input
  traverse(s)

  -- this to add [] bracket to table attributes
  s.output = normalize_table_keys(s.output)

  -- encapsulate output if doctype exist
  if s.doc_type ~= nil then
    s:conc(")")
  end

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
  local file = io.open(luax_file, "r")
  if not file then
    return original_require(module_name)
  end
  file:close()
  local str = preprocess_lua_file(luax_file)
  return load(str)()
end

return h
