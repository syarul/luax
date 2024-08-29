## LuaX
Shallow React createElement implementation in LUA.

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
