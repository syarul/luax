local h = require('h')

local originalRequire = require

local function decentParserAST(input)
  local output = ""
  local pos = 1
  local deepNode = 0
  local deepString = false
  local deepStringApos = false
  local isTag = false
  local textNode = false
  local textNodeStart = false
  local var = false

  while pos <= #input do
    local tok = input:sub(pos, pos)
    -- simple decent parser
    -- escape " ' encapsulation
    -- opening tag
    if tok == "<" and not deepString and not deepStringApos then
      local nextSpacingPos = input:find('%s',pos)
      local tagRange = input:sub(pos, nextSpacingPos)
      local tagName = tagRange:match("<(%w+)", 0)
      local tagNameEnd = tagRange:match("</(%w+)>", 0)
      if tagName then deepNode = deepNode + 1 end
      if tagNameEnd then deepNode = deepNode - 1 end
      pos = pos + 1
      
      if tagName and not deepString then
        isTag = true
        textNode = false
        if deepNode > 1 then
          output = output .. ", " .. tagName .. "({"
        else
          output = output .. tagName .. "({"
        end
        local step = 1
        -- enclose attributes if it empty
        if tagRange:sub(#tagRange-1, #tagRange):gsub("[\r\n]", ""):match("^%s*(.-)$") == '>' then step = 0 end
        pos = pos + #tagName + step
      elseif tagNameEnd then
        if isTag and not textNode then
          isTag = not isTag
          local trail = input:sub(0, pos-2):gsub("[%s\r\n]", "")
          if trail:sub(#trail-1, #trail-1) == '/' then
            output = output .. ")"
          else
            output = output .. "})"
          end
        elseif isTag and textNode then
          output = output .. "]])"
        else
          if textNodeStart then
            textNodeStart = not textNodeStart
            output = output .. "]])"
          else
            output = output .. ")"
          end
        end
        pos = pos + #tagNameEnd + 2
      else
        output = output .. tok
        pos = pos + 1
      end
    elseif tok == '"' and deepNode > 0 then
      deepString = not deepString
      output = output .. tok
      pos = pos + 1
    elseif tok == "'" and deepNode > 0 then
      deepStringApos = not deepStringApos
      output = output .. tok
      pos = pos + 1
    elseif tok == ">" and deepNode > 0 and not deepString and not deepStringApos then
      if not textNode and isTag and input:sub(pos-1, pos-1) ~= "/" then
        isTag = not isTag
        textNode = not textNode
        output = output .. '}'
      else
        isTag = not isTag
        -- textNode = not textNode
        output = output .. '})'
      end
      pos = pos + 1
    elseif tok == "/" and input:sub(pos+1, pos+1) == '>' and not deepString and not deepStringApos then
      deepNode = deepNode - 1
      output = output .. '})'
      pos = pos + 2
    elseif tok == '{' and deepNode > 0 and not deepString and not deepStringApos then
      var = not var
      if not isTag then
        output = output .. ','
      end
      pos = pos + 1
    elseif tok == '}' and deepNode > 0 and not deepString and not deepStringApos then
      var = not var
      pos = pos + 1
    elseif deepNode > 0 and not deepString and not deepStringApos then
      if tok:match("%s") then
        if isTag and output:sub(-1) ~= "{" and output:sub(-1) == "\"" or
          isTag and input:sub(pos -1, pos -1) == "}" then
          output = output .. ","
        end
      end

      if textNode and not textNodeStart then
        local subNode = input:match("%s*<(%w+)", pos)
        if not isTag and not subNode and not var then
          textNodeStart = not textNodeStart
          output = output .. ", [["
        end
      end

      output = output .. tok
      pos = pos + 1
    else
      if not textNode and not deepString and not deepStringApos then
        textNode = not textNode
        if textNode then
          local subNode = input:match("%s*<(%w+)", pos)
          if isTag and not subNode then
            output = output .. "}, [["
          elseif deepNode > 0 and not subNode then
            output = output .. "[["
          end
        end
      end
      output = output .. tok
      pos = pos + 1
    end
  end
  return output
end

local function preprocessLuaFile(inputFile)
  local inputCode = io.open(inputFile, "r"):read("*all")
  local transformedCode = decentParserAST(inputCode)
  -- this to add [] bracket to table attributes
  transformedCode = transformedCode:gsub('([%w%-_]+)%=([^%s]+)', '["%1"]=%2')
  -- print(transformedCode)
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
