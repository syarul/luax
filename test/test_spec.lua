function GetDir()
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

package.path = package.path .. ";" .. GetDir() .. "/?.lua"

local h = require("luax")

describe("LuaX", function()
  it("should return type function", function()
    assert.is.equal("function", type(h))
  end)
  it("should return a HTML string with createElement", function()
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
    local el = require("test.1_div")
    assert.is.equal('<div></div>', h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.2_node_value")
    assert.is.equal('<div>xxxx</div>', h(el))
  end)

  it("should return a HTML string when given attributes with special characters", function()
    local el = require("test.4_content")
    assert.is.equal(
    '<footer _="install Footer" class="footer"><span _="install TodoCount" class="todo-count" hx-trigger="load"></span>foobar</footer>',
      h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.5_element")
    assert.is.equal('<div bar="bar" class="container" d="1" id="foo" val="value">Hello, world!</div>', h(el))
  end)

  it("should return a HTML string when given children prop", function()
    local el = require("test.6_foo")
    assert.is.equal('<div>foobar</div>', h(el))
  end)
  
  it("should return a HTML string when have conditional statement", function()
    local el = require("test.7_input_with_con")
    assert.is.equal(
    '<input _="install TodoEdit" class="edit" name="title" todo-id="0">',
      h(el))
  end)

  it("should return a HTML string when given input node", function()
    local module = require("test.8_input")
    assert.is.equal(
    '<input _="install TodoEdit" class="edit" name="title" todo-id="1" value="task">',
      h(module.EditTodo({ editing = true, title = "task", id = "1" })))
  end)

  it("should return a HTML string when given input node", function()
    local el = require("test.9_input2")
    assert.is.equal(
    '<input _="install TodoCheck" class="toggle" hx-patch="/toggle-todo?id=1&done=false" hx-swap="outerHTML" hx-target="closest <li/>" type="checkbox">',
      h(el))
  end)

  it("should return a HTML string with multi breakline", function()
    local el = require("test.10_line_break")
    assert.is.equal(
    '<div><p color="red">foobar!</p>       </div>',
      h(el))
  end)

  it("should return a HTML string when given JSX like syntax", function()
    local el = require("test.11_props")
    assert.is.equal([[<div id="foo" style="color;red">    test
  </div>]], h(el))
  end)

  it("should return a HTML string with deep node tree", function()
    local el = require("test.12_test")
    assert.is.equal(
    '<li _="on destroy my.querySelector(\'button\').click()" class="test" id="1"><div class="view">todo A<label _="install TodoDblclick" hx-patch="/edit-todo?id=1&foo=test" hx-swap="outerHTML" hx-target="next input" hx-trigger="dblclick">todo A Label</label><button _="install Destroy" class="destroy" hx-delete="/remove-todo?id=1" hx-swap="outerHTML" hx-target="closest <li/>" hx-trigger="click"></button></div>todo A Value</li>',
      h(el))
  end)

  it("should return a HTML string when given JSX like syntax with nested node", function()
    local el = require("test.13_varin")
    assert.is.equal('<div class="container" id="div_1"><p class="title" id="p_2" style="border: 1px solid red;">Hello, world!</p></div>', h(el))
  end)
  
end)
