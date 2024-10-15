## LuaX

LuaX is Lua + XML Syntax extension with built-in decent parse. In retrospect it's akin to React JSX.

<a href="https://luarocks.org/modules/syarul/luax" rel="nofollow"><img alt="Luarocks Package" src="https://img.shields.io/badge/Luarocks-1.0.5-blue.svg" style="max-width:100%;"></a>
[![Lua CI](https://github.com/syarul/luax/actions/workflows/lua.yml/badge.svg)](https://github.com/syarul/luax/actions/workflows/lua.yml)

## Decent Parser
Initial inspiration comes from [https://bvisness.me/luax/](https://bvisness.me/luax/). The reason is to make it simpler with support of Lua `metaprogramming` where node `tags` is handle automatically without defining it.

### Usage

Install with `Luarocks`

`luarocks install luax`

If you only need the pragma without handling transpiling lua files, load the `LuaX` `h` pragma **only** with
```lua
local h = require('h')

print(h(div({ style = "color: red;" }, "Hello from LuaX!")))
```

You'll get,

```html
<div style="color: red;">Hello from LuaX!</div>
```
So how to use with actual HTML syntax in Lua? First create a `*.luax` file,

```lua
-- el.luax
local attr = { style="color: red;" }
return <div style={attr.stlye}>hello from LuaX!</div>
```

import it on to the main
```lua
-- import luax transpiler to handle the parsing of *.luax file
local h = require('luax')

local el = require('el')

print(h(el))
```

You'll get,

```html
<div style="color: red;">Hello from LuaX!</div>
```

Sample usage with table structure

```lua
local function map(a, fcn)
  local b = {}
  for _, v in ipairs(a) do
    table.insert(b, fcn(v))
  end
  return b
end

local filters = {
  { url = "#/",          name = "All",       selected = true },
  { url = "#/active",    name = "Active",    selected = false },
  { url = "#/completed", name = "Completed", selected = false },
}

local content = table.concat(map(filters, function(filter)
  -- convert to string
  return h(<li>
    <a
      class={filter.selected and 'selected' or nil}
      href={filter.url}
      _="on click add .selected to me"
    >
      {filter.name}
    </a>
  </li>)
end), '\n')

return <ul class="filters" _="on load set $filter to me">
    {content}
</ul>
```

See the test folder to see more usage cases.

## Sample Project
[https://github.com/syarul/todomvc-lua-luasocket-htmx-_hyperscript](https://github.com/syarul/todomvc-lua-luasocket-htmx-_hyperscript)

## Caveats

- Since nodeName such `div`, `p`, etc+ are used as declared variables, so do **NOT** declare a function with the same name i.e.,

```lua
local function li()
  return <li>todo 1</li>
end

```
- when using `table.concat` you need to convert to string so encapsulate with `h` pragma,
- defining in bracket try to limit by using `'` instead of `"` i.e., `{foo and 'foo' or nil}`,
- leave attributes assignment with no spacing `{ foo="foo" }` instead of `{ foo = "foo" }`,
- <!--> HTML comments, not supported yet.