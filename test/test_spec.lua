-- luacheck: globals DOCTYPE doctype html head body describe it div p span
local function GetDir()
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

  it("should return type HTML doctype", function()
    local el = DOCTYPE({ "html" }, html({}, head({}), body({})))
    assert.is.equal("<!doctype html><html><head></head><body></body></html>", h(el))
  end)

  it("should return type HTML doctype with string attributes", function()
    local el = DOCTYPE({ "HTML", "PUBLIC", "\"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"" })
    assert.is.equal([[<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">]], h(el))
  end)

  it("should return type HTML doctype", function()
    local doc_type = require('test.19_doctype_setter')
    assert.is.equal('<!doctype html><html><head></head><body></body></html>', h(doc_type))
  end)

  it("should return type HTML doctype with string attributes", function()
    local doc_type_comp = require('test.20_doctype_setter_comp')
    assert.is.equal('<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><head></head><body></body></html>', h(doc_type_comp))
  end)

  it("should return a HTML string when given XML like syntax", function()
    local el = require("test.02_node_value")
    assert.is.equal('<div>xxxx</div>', h(el))
  end)

  it("should return a HTML string when given attributes with special characters", function()
    local el = require("test.04_content")
    assert.is.equal(
    '<footer _="install Footer" class="footer"><span _="install TodoCount" class="todo-count" hx-trigger="load"></span>foobar</footer>',
      h(el))
  end)

  it("should return a HTML string when given XML like syntax", function()
    local el = require("test.05_element")
    assert.is.equal('<div bar="bar" class="container" d="1" id="foo" val="value">Hello, world!</div>', h(el))
  end)

  it("should return a HTML string when given children prop", function()
    local el = require("test.06_foo")
    assert.is.equal('<div>foobar</div>', h(el))
  end)

  it("should return a HTML string when have conditional statement", function()
    local el = require("test.07_input_with_con")
    assert.is.equal(
    '<input _="install TodoEdit" class="edit" name="title" todo-id="0">',
      h(el))
  end)

  it("should return a HTML string when given input node", function()
    local module = require("test.08_input")
    assert.is.equal(
    '<input _="install TodoEdit" class="edit" name="title" todo-id="1" value="task">',
      h(module.EditTodo({ editing = true, title = "task", id = "1" })))
  end)

  it("should return a HTML string when given input node", function()
    local el = require("test.09_input2")
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

  it("should return a HTML string when given XML like syntax", function()
    local el = require("test.11_props")
    assert.is.equal([[<div id="foo" style="color;red">    test
  </div>]], h(el))
  end)

  it("should return a HTML string with deep node tree", function()
    local el = require("test.12_test")
    assert.is.equal(
    [[<li _="on destroy my.querySelector('button').click()" class="test" id="1"><div class="view">todo A<label _="install TodoDblclick" hx-patch="/edit-todo?id=1&foo=test" hx-swap="outerHTML" hx-target="next input" hx-trigger="dblclick">todo A Label          </label><button _="install Destroy" class="destroy" hx-delete="/remove-todo?id=1" hx-swap="outerHTML" hx-target="closest <li/>" hx-trigger="click"></button></div>todo A Value</li>]],
      h(el))
  end)

  it("should return a HTML string when given XML like syntax with nested node", function()
    local el = require("test.13_varin")
    assert.is.equal('<div class="container" id="div_1"><p class="title" id="p_2" style="border: 1px solid red;">Hello, world!</p></div>', h(el))
  end)

  it("should return a HTML string when given XML like syntax with nested node", function()
    local el = require("test.14_page")
    assert.is.equal([[<html data-framework="htmx" lang="en"><head><meta charSet="utf-8"><title>HTMX • TodoMVC</title><link href="https://unpkg.com/todomvc-common@1.0.5/base.css" rel="stylesheet" type="text/css"><link href="https://unpkg.com/todomvc-app-css/index.css" rel="stylesheet" type="text/css"><script src="/hs/start-me-up._hs" type="text/hyperscript"></script><script src="/hs/main._hs" type="text/hyperscript"></script><script src="/hs/behaviors/toggle-main._hs" type="text/hyperscript"></script><script src="/hs/behaviors/toggle-footer._hs" type="text/hyperscript"></script><script src="/hs/behaviors/toggle-show._hs" type="text/hyperscript"></script><script src="/hs/behaviors/add-todo._hs" type="text/hyperscript"></script><script src="/hs/behaviors/footer._hs" type="text/hyperscript"></script><script src="/hs/behaviors/toggle-all._hs" type="text/hyperscript"></script><script src="/hs/behaviors/clear-completed._hs" type="text/hyperscript"></script><script src="/hs/behaviors/destroy._hs" type="text/hyperscript"></script><script src="/hs/behaviors/todo-count._hs" type="text/hyperscript"></script><script src="/hs/behaviors/todo-dblclick._hs" type="text/hyperscript"></script><script src="/hs/behaviors/todo-check._hs" type="text/hyperscript"></script><script src="/hs/behaviors/todo-edit._hs" type="text/hyperscript"></script></head><body><section _="install ToggleMain end install ToggleFooter end install ToggleShow end" class="todoapp"><header class="header"><h1>todos</h1><input _="install AddTodo" class="new-todo" id="add-todo" name="title" placeholder="What needs to be done?"></header>toggleMaintodoListtodoFooter</section><footer _="on load debounced at 10ms call startMeUp() hashCache()" class="info"><p>Double-click to edit a todo</p><p>Created by <a href="http://github.com/syarul/">syarul</a></p><p>Part of <a href="http://todomvc.com">TodoMVC</a></p><img height="auto" src="https://htmx.org/img/createdwith.jpeg" width="250"></footer></body><script src="https://unpkg.com/todomvc-common@1.0.5/base.js"></script><script src="https://unpkg.com/htmx.org@1.9.10"></script><script src="https://unpkg.com/hyperscript.org/dist/_hyperscript.js"></script></html>]], h(el.Page("todos")))
  end)

  local filters = {
    { url = "#/",          name = "All",       selected = true },
    { url = "#/active",    name = "Active",    selected = false },
    { url = "#/completed", name = "Completed", selected = false },
  }

  it("should return a HTML string when given XML like syntax with table concat", function()
    local el = require("test.17_table")
    assert.is.equal([[<ul _="on load set $filter to me" class="filters"><li><a _="on click add .selected to me" class="selected" href="#/">All      </a>    </li>
<li><a _="on click add .selected to me" href="#/active">Active      </a>    </li>
<li><a _="on click add .selected to me" href="#/completed">Completed      </a>    </li>  </ul>]], h(el.Filter(filters)))
  end)

  it("should return a HTML string when given XML like syntax with table concat", function()
    local el = require("test.18_filter")
    assert.is.equal([[<ul class="todo-list"><li><a _="on click add .selected to me" class="selected" href="#/">All    </a>  </li>
<li><a _="on click add .selected to me" href="#/active">Active    </a>  </li>
<li><a _="on click add .selected to me" href="#/completed">Completed    </a>  </li></ul>]], h(el(filters)))
  end)

  it("should return a HTML string when given XML like syntax with kebab-case tag", function()
    local fui = require("test.21_web_component")
    assert.is.equal([[<fluent-button-test><fci-button>Example</fci-button></fluent-button-test>]], h(fui))
  end)


  it("should return a HTML string when given XML like syntax with script tag", function()
    local scriptTag = require("test.22_script_tag")
    assert.is.equal([[<div><script>
        class CounterElement extends HTMLElement {
            constructor() {
                super();
                this.attachShadow({ mode: 'open' });
            }

            connectedCallback() {
                console.log(1)
            }
        }

        customElements.define('counter-element', CounterElement);
    </script></div>]], h(scriptTag))
  end)

  it("should return a HTML string when given XML like syntax with script tag", function()
    local st2 = require('test.23_web_component_test')
    assert.is.equal([[<!doctype html><html><head><script src="https://unpkg.com/@fluentui/web-components" type="module"></script></head><body><counter-element></counter-element><script>
                class CounterElement extends HTMLElement {
                    constructor() {
                        super();
                        this.attachShadow({ mode: 'open' });
                        this.count = 0;
                        this.shadowRoot.innerHTML = `
                            <fluent-card>
                                <p>Count: <span id="count">${this.count}</span></p>
                                <fluent-button id="increment">Increment</fluent-button>
                                <fluent-button id="decrement" _="foo">Decrement</fluent-button>
                            </fluent-card>
                        `;
                    }

                    connectedCallback() {
                        this.shadowRoot.querySelector('#increment').addEventListener('click', () => this.increment());
                        this.shadowRoot.querySelector('#decrement').addEventListener('click', () => this.decrement());
                    }

                    increment() {
                        this.count++;
                        this.updateCount();
                    }

                    decrement() {
                        this.count--;
                        this.updateCount();
                    }

                    updateCount() {
                        this.shadowRoot.querySelector('#count').textContent = this.count;
                    }
                }

                customElements.define('counter-element', CounterElement);
            </script></body></html>]], h(st2))
  end)

  it("should return a HTML string when given XML like syntax with script tag", function()
    local st3 = require('test.24_web_component_style')
    assert.is.equal([[<!doctype html><html><head><style>
            button {
                background-color: red;
                display: block;
                margin-top: 8px;
            }

            example-component::part(native) {
                background-color: pink;
            }
        </style></head><body><example-component></example-component><button>Button in Light DOM</button><script>
            // Use custom elements API v1 to register a new HTML tag and define its JS behavior
            // using an ES6 class. Every instance of <fancy-tab> will have this same prototype.
            customElements.define('example-component', class extends HTMLElement {
                constructor() {
                    super(); // always call super() first in the constructor.

                    // Attach a shadow root to <fancy-tabs>.
                    const shadowRoot = this.attachShadow({mode: 'open'});
                    shadowRoot.innerHTML = `
                        <style>
                            div {
                                height: 150px;
                                width: 150px;
                                border: solid 2px;
                            }
                        </style>

                        <div part="native"></div>
                        <button>Button in Shadow DOM</button>
                    `;
                }
            });
        </script></body></html>]], h(st3))
  end)

end)
