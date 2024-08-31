## LuaX
Shallow React createElement implementation in LUA. Inspired by https://bvisness.me/luax/. Also support JSX like syntax parsing

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
