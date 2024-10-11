package = "luax"
version = "1.0.0-1"

source = {
    url = "https://github.com/syarul/luax/archive/refs/tags/v1.0.0.tar.gz",
    dir = "luax-1.0.0"
}
description = {
    summary = "HTML parse in Lua",
    detailed = "Decent parse for HTML, so you don't have to write as concatenates string",
    homepage = "https://github.com/syarul/luax",
    license = "MIT"
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        luax = "luax.lua"
    }
}
