local h = require('h')

local originalRequire = require

local function decentParserAST(input)
  local pos = 1
  local output = ""
  local isTag = 0
  local isTextNode = 0

  while pos <= #input do
    local char = input:sub(pos, pos)
    -- simple decent parser
    -- opening tag
    if char == "<" then
      local tagName = input:match("<(%w+)", pos)
      local tagNameEnd = input:match("</(%w+)>", pos)
      if isTag == 2 and tagName ~= nil then
        -- children tag
        output = output .. ", "
      end
      if tagName then
        isTag = 1
        output = output .. tagName .. "({"
        pos = pos + #tagName + 1
      elseif tagNameEnd then
        isTag = 0
        if isTextNode == 2 then
          isTextNode = 0
          output = output .. "\")"
        else
          output = output .. ")"
        end
        pos = pos + #tagNameEnd + 2
      else
        pos = pos + 1
      end
    elseif char == ">" then
      if isTag == 1 then 
        output = output .. " }"
        isTag = 2
      end
      pos = pos + 1
    elseif char == "/" then
      -- self closing tag
      isTag = 0
      output = output .. " })"
      pos = pos + 1
    else
      local skip = false
      if char and isTag == 2 then
        isTextNode = 1
        isTag = 3
        output = output .. ", "
      elseif isTag == 1 then
        -- attributes
        if char:match("%s") then
          if  output:sub(-1) ~= "{" and output:sub(-1) == "\"" then
            output = output .. ","
          elseif  input:sub(pos -1, pos -1) == "}" then
            output = output .. ","
          end
          skip = false
        elseif char == "{" or char == "}" then
          skip = true
        end

      end
      if isTag ~= 0 then
        if isTextNode == 1 and char == "{" or char == "}" then
          skip = true
          isTextNode = 3
        elseif isTextNode == 1 then
          isTextNode = 2
          output = output .. "\""
        end
      end

      if skip == false then
        output = output .. char
      end
      pos = pos + 1
    end
  end
  return output
end

local function preprocessLuaFile(inputFile)
  local inputCode = io.open(inputFile, "r"):read("*all")
  local transformedCode = decentParserAST(inputCode)
  return transformedCode
end

function require(moduleName)
  local luaxFile = moduleName:gsub("%.", "/") .. ".luax"
  local luaFile = moduleName:gsub("%.", "/") .. ".lua"
  local file = io.open(luaxFile, "r")
  if file then
    file:close()
    local str = preprocessLuaFile(luaxFile)
    -- eval back to buffer file after transform
    luaFile = load(str)()
  else
    return originalRequire(moduleName)
  end
  return luaFile
end

return h
