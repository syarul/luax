## LuaX
React JSX implementation in LUA. 

<a href="https://luarocks.org/modules/syarul/luax" rel="nofollow"><img alt="Luarocks Package" src="https://img.shields.io/badge/Luarocks-1.0.0-blue.svg" style="max-width:100%;"></a>
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

### Usage with JSX like syntax

This require parsing it to the createElement.

first create a luax file

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

> Inspired by https://bvisness.me/luax/.
