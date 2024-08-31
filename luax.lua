local h = require('h')

local originalRequire = require

local function tokenize(input)
  local pos = 1
  local output = ""

  while pos <= #input do
    local char = input:sub(pos, pos)

    if char == "<" then
      if input:sub(pos + 1, pos + 1) == "/" then
        local tagName = input:match("</(%w+)>", pos)
        pos = pos + #tagName + 3 -- skip "</tag>"
        output = output .. ")"   -- close the Lua function call
      else
        local tagName = input:match("<(%w+)", pos)
        pos = pos + #tagName + 1           -- skip "<tag>"
        output = output .. tagName .. "({" -- opening the Lua function call

        local tagEnd = input:find(">", pos)

        if true then
          local attributesString = input:sub(pos, tagEnd)
          local attributes = {}
          local attrPos = 1
          while attrPos <= #attributesString do
            local attrNameBracket, attrValueBracket, endPosBracket = attributesString:match(
              '%s*(%w+)%s*=%s*{([^}]*)}%s*()', attrPos)
            local attrName, attrValue, endPos = attributesString:match('%s*(%w+)%s*=%s*"([^\'"]*)"%s*()', attrPos)
            if attrName then
              table.insert(attributes, attrName .. ' = "' .. attrValue .. '"')
              attrPos = endPos
              pos = pos + #attrName + #attrValue + 3
            elseif attrNameBracket then
              table.insert(attributes, attrNameBracket .. ' = ' .. attrValueBracket)
              attrPos = endPosBracket
              pos = pos + #attrNameBracket + #attrValueBracket + 3
            else
              break
            end
          end
          pos = pos + #attributes
          output = output .. table.concat(attributes, ", ") -- add delimiter
        end
      end
    elseif char == "{" then
      -- handle content inside curly braces
      local content = input:match("{(.-)}", pos)
      output = output .. content:match("%s*(.*)%s*")
      pos = pos + #content + 2 -- skip "{content}"
    elseif char == "}" then
      pos = pos + 1
    else
      if char == ">" then
        pos = pos + 1
        output = output .. "}, " -- opening the Lua function call
        local text = input:match("([^<]+)", pos)
        local textEnd = input:find("<", pos)
        local bracket = input:match("{(.-)}", pos)
        if not bracket and text and pos < textEnd then
          local str = text:match("^%s*(.-)%s*$")
          output = output .. '"' .. str .. '"'
          pos = pos + #text
        end
      else
        output = output .. char
        pos = pos + 1
      end
    end
  end
  return output
end

local function preprocessLuaFile(inputFile)
  local inputCode = io.open(inputFile, "r"):read("*all")
  local transformedCode = tokenize(inputCode)
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
