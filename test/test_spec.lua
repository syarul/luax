function getDir()
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

local h = require("h")

local el = div(
  { class = "container" },
  p({ class = "title" }, "Hello, world!"),
  span({ style = "color: red;" }, "This is a span")
)

describe("LuaX", function()
  it("should pass this basic test", function()
    assert.is_true(true)
  end)
  it("h should return a function", function()
    assert.is.equal("function", type(h))
  end)
  it("h should return a createElement DSL", function()
    assert.is.equal('<div class="container"><p class="title">Hello, world!</p><span style="color: red;">This is a span</span></div>', h(el))
  end)
end)
