package = "luax"
version = "1.0.1-2"

source = {
    url = "https://github.com/syarul/luax/archive/refs/tags/v1.0.1.tar.gz",
    dir = "luax-1.0.1"
}
description = {
    summary = "HTML parse in Lua",
    detailed = [[## LuaX
Decent parse for HTML, so you don't have to write as concatenates string, in short a React JSX implementation in LUA. 

<a href="https://luarocks.org/modules/syarul/luax" rel="nofollow"><img alt="Luarocks Package" src="https://img.shields.io/badge/Luarocks-1.0.1-blue.svg" style="max-width:100%;"></a>
[![Lua CI](https://github.com/syarul/luax/actions/workflows/lua.yml/badge.svg)](https://github.com/syarul/luax/actions/workflows/lua.yml)

### Usage

```lua
local h = require('h')

local el = div(
  { class = "container" },
  p({ class = "title" }, "Hello, world!"),
  span({ style = "color: red;" }, "This is a span")
)

print(h(el))
```

You'll get,

```html
<div class="container"><p class="title">Hello, world!</p><span style="color: red;">This is a span</span></div>
```

### Usage with JSX like syntax (HTML inside Lua)

first create a `*.luax` file, then import the `LuaX` pragma `h`

```lua
-- el.luax
local class = "container"
local el = <div id="hello" class={class}>Hello, world!</div>
return el
```

import it on to the main
```lua
local h = require('luax')

local el = require('el')

print(h(el))
```

You'll get,

```html
<div class="container" id="hello">Hello, world!</div>
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
]],
    homepage = "https://github.com/syarul/luax",
    license = "MIT"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        luax = "luax.lua",
        h = "h.lua"
    }
}
