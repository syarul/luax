local function getDir()
  local handle
  local result
  if os.getenv("OS") == "Windows_NT" then
    handle = io.popen("cd")
  else
    handle = io.popen("pwd")
  end
  if handle then
    result = handle:read("*a"):gsub("%s+", "")
    handle:close()
  else
    result = "Failed to get directory"
  end

  return result
end

package.path = package.path .. ";" .. getDir() .. "/?.lua"

local h = require('luax')

-- local div = require('test.1_div')

-- h(div)

-- local node_value = require('test.2_node_value')

-- h(node_value)

-- local content = require('test.4_content')

-- h(content)

-- local element = require('test.5_element')

-- h(element)

-- local foo = require('test.6_foo')

-- h(foo)

-- local input_with_con = require('test.7_input_with_con')

-- h(input_with_con)

-- local module = require('test.8_input')

-- h(module.EditTodo({ editing = true, title = "task", id = "1" }))

-- local input2 = require('test.9_input2')

-- h(input2)

-- local linebreak = require('test.10_line_break')

-- h(linebreak)

-- local props = require('test.11_props')

-- h(props)

-- local test = require('test.12_test')

-- h(test)

-- local varin = require('test.13_varin')

-- h(varin)

-- local page = require('test.14_page')

-- print(h(page.Page("todos")))

-- local title = require('test.15_title')

-- print(h(title))

-- local p = require('test.16_p')

-- print(h(p))

local filters = {
  { url = "#/",          name = "All",       selected = true },
  { url = "#/active",    name = "Active",    selected = false },
  { url = "#/completed", name = "Completed", selected = false },
}

local table = require('test.17_table')
print(h(table.Filter(filters)))

-- local f = require('test.18_filter')
-- print(h(f(filters)))


