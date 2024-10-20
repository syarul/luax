local socket = require("socket")
local url = require("socket.url")
local server = socket.tcp()

local function get_dir()
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

package.path = package.path .. ";" .. get_dir() .. "/?.lua"

local h = require("luax")

local function read_static_file(file_path)
    local file, err = io.open(file_path, "rb") -- in binary mode
    if not file then
        return nil, "Error opening file: " .. err
    end

    local content = file:read("*all")
    file:close()
    return content
end

local mimes = {
    json = 'application/json',
    js = 'application/javascript'
}

local function get_mime_type(path)
    return mimes[path:lower():match("[^.]*$")] or "application/octet-stream"
end

local function get_headers(client, headers)
    while true do
        local line, _ = client:receive()
        if line == "" or line == nil then
            break
        else
            local key, value = line:match("^(.-):%s*(.*)$")
            if key and value then
                if key:lower() == "cookie" then
                    headers[key:lower()] = value
                    break -- only read cookie
                end
            end
        end
    end
end

local function render(client, status_code, body, custom_headers)
    local header_string = "HTTP/1.1 " .. status_code .. "\r\n"
    local headers = {
        ["Content-Type"] = "text/html"
    }
    if type(custom_headers) == "table" then
        for k, v in pairs(custom_headers) do
            headers[k] = v
        end
    end
    for k, v in pairs(headers) do
        header_string = header_string .. k .. ": " .. v .. "\r\n"
    end
    header_string = header_string .. "\r\n"
    if type(body) == "table" then
        body = h(body)
    end
    client:send(header_string .. (body or ""))
end

local app = require("examples.web-component.app.app")

local function handler(client, request)
    if request then
        local method, path = request:match("^(%w+)%s([^%s]+)%sHTTP")

        local parsed_url = url.parse(path)

        if parsed_url.path == "/" then
            -- printTable(app)
            local html = h(app)
            render(client, "200 OK", html)
        elseif mimes[parsed_url.path:lower():match("[^.]*$")] and method == "GET" then
            local file = parsed_url.path
            local content_type = get_mime_type(file)
            local content, err = read_static_file(file)
            if not err then
                render(client, "200 OK", content, { ["Content-Type"] = content_type })
            else
                render(client, "404 Not Found", "Not Found", { ["Content-Type"] = "text/plain" })
            end
        else
            -- 404
            render(client, "404 Not Found", "Not Found", { ["Content-Type"] = "text/plain" })
        end
    end
end

server:bind("*", 8888)
server:listen()
server:settimeout(0)

print('Lua Socket TCP Server running at http://127.0.0.1:8888/')

while true do
    -- Check for new connections
    local client = server:accept()
    if client then
        client:settimeout(10)
        local headers = {}
        local request, err = client:receive()
        if not err then
            get_headers(client, headers)
            handler(client, request)
        end
        client:close()
    end
end
