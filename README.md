## LuaX
Decent parse for HTML, so you don't have to write as concatenates string, in short a React JSX implementation in LUA. 

<a href="https://luarocks.org/modules/syarul/luax" rel="nofollow"><img alt="Luarocks Package" src="https://img.shields.io/badge/Luarocks-1.0.1-blue.svg" style="max-width:100%;"></a>
[![Lua CI](https://github.com/syarul/luax/actions/workflows/lua.yml/badge.svg)](https://github.com/syarul/luax/actions/workflows/lua.yml)

### Usage

Install with `Luarocks`

`luarocks install luax`

load the `LuaX` `h` pragma **only** with
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
-- import luax to handle the parsing of *.luax file
local h = require('luax')

local el = require('el')

print(h(el))
```

You'll get,

```html
<div style="color: red;">Hello from LuaX!</div>
```

Sample usage with list/table structure

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

> Inspired by https://bvisness.me/luax/.
