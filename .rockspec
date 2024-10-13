package = "luax"
version = "1.0.2-1"

source = {
    url = "https://github.com/syarul/luax/archive/refs/tags/v1.0.2.tar.gz",
    dir = "luax-1.0.2"
}
description = {
    summary = "HTML parse in Lua",
    detailed = "LuaX is Lua + XML Syntax extension with builtin decent parse. In retrospect it's akin to React JSX.",
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
