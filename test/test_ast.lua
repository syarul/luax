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

local div = require('test.1_div')

print(h(div))

local node_value = require('test.2_node_value')

print(h(node_value))

-- local comment = require('test.3_comment')

-- print(h(comment))

local element = require('test.element')

print(h(element))

local varin = require('test.varin')

print(h(varin))

local foo = require('test.foo')

print(h(foo))

local content = require('test.content')

print(h(content))
