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

local h = require("luax")

describe("LuaX", function()
  it("should return type function", function()
    assert.is.equal("function", type(h))
  end)
  it("should return a HTML string with createElement DSL", function()
    local el = div(
      { class = "container" },
      p({ class = "title" }, "Hello, world!"),
      span({ style = "color: red;" }, "This is a span")
    )
    assert.is.equal(
    '<div class="container"><p class="title">Hello, world!</p><span style="color: red;">This is a span</span></div>',
      h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.element")
    assert.is.equal('<div bar="bar" class="container" d="1" id="foo" val="value">Hello, world!</div>', h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.foo")
    assert.is.equal('<div>foo</div>', h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.varin")
    assert.is.equal(
    '<div class="container" id="div_1"><p class="title" id="p_2" style="border: 1px solid red;">Hello, world!</p></div>',
      h(el))
  end)
end)
