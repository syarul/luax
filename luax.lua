local h = require('h')

local originalRequire = require

local function resetTable(store, data)
  for key, value in pairs(data) do
    store[key] = value
  end
end

local function decentParserAST(input)
  local output = ""
  local pos = 1
  local var = false
  local s = {
    deepNode = 0,
    deepString = false,
    deepStringApos = false,
    isTag = false,
    textNode = false,
    textNodeStart = false
  }
  local resetStore = {}
  resetTable(resetStore, s)
  local varStore = {}

  while pos <= #input do
    local tok = input:sub(pos, pos)
    -- simple decent parser
    -- escape " ' encapsulation
    -- opening tag
    if tok == "<" and not s.deepString and not s.deepStringApos then
      local nextSpacingPos = input:find("%s", pos)
      local tagRange = input:sub(pos, nextSpacingPos)
      local tagName = tagRange:match("<(%w+)", 0)
      local tagNameEnd = tagRange:match("</(%w+)>", 0)
      if tagName then s.deepNode = s.deepNode + 1 end
      pos = pos + 1

      if tagName and not s.deepString then
        s.isTag = true
        s.textNode = false
        if s.textNodeStart then
          s.textNodeStart = not s.textNodeStart
          output = output .. "]]"
        end
        if s.deepNode > 1 then
          -- handle internal return function
          local ret = input:sub(pos-8, pos):gsub("%s\r\n", ""):sub(0, 6) == "return"
          if ret then
            output = output .. tagName .. "({"
          else
            output = output .. ", " .. tagName .. "({"
          end
        else
          output = output .. tagName .. "({"
        end
        pos = pos + #tagName
      elseif tagNameEnd then
        s.deepNode = s.deepNode - 1
        if s.isTag and not s.textNode then
          s.isTag = not s.isTag
          local trail = input:sub(0, pos - 2):gsub("[%s\r\n]", "")
          if trail:sub(#trail - 1, #trail - 1) == "/" then
            output = output .. ")"
          else
            output = output .. "})"
          end
        elseif s.isTag and s.textNode then
          output = output .. "]])"
        else
          if s.textNodeStart then
            s.textNodeStart = not s.textNodeStart
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
    elseif tok == '"' and s.deepNode > 0 then
      s.deepString = not s.deepString
      output = output .. tok
      pos = pos + 1
    elseif tok == "'" and s.deepNode > 0 then
      s.deepStringApos = not s.deepStringApos
      output = output .. tok
      pos = pos + 1
    elseif tok == ">" and s.deepNode > 0 and not s.deepString and not s.deepStringApos then
      if not s.textNode and s.isTag and input:sub(pos - 1, pos - 1) ~= "/" then
        s.isTag = not s.isTag
        s.textNode = not s.textNode
        output = output .. "}"
      else
        s.isTag = not s.isTag
        s.deepNode = s.deepNode - 1
        output = output .. "})"
      end
      pos = pos + 1
    elseif tok == "/" and input:sub(pos + 1, pos + 1) == ">" and not s.deepString and not s.deepStringApos then
      s.deepNode = s.deepNode - 1
      output = output .. "})"
      pos = pos + 2
    elseif tok == "{" and s.deepNode > 0 and not s.deepString and not s.deepStringApos then
      var = not var
      if var then
        -- snapshot currentState
        resetTable(varStore, s)
        -- reset currentState
        resetTable(s, resetStore)
      end
      local trail = input:sub(pos - 20, pos-1):gsub("[%s\r\n]", "")
      if trail:sub(#trail) == ">" or trail:sub(#trail) == "}" then
        output = output .. ", "
      end
      pos = pos + 1
    elseif tok == "}" and var then
      var = not var
      if not var then
        -- restore currentState from snapshot
        resetTable(s, varStore)
      end
      pos = pos + 1
    elseif s.deepNode > 0 and not s.deepString and not s.deepStringApos then
      if tok:match("%s") then
        if not var and s.isTag and output:sub(-1) ~= "{" and output:sub(-1) == "\"" or
            s.isTag and input:sub(pos - 1, pos - 1) == "}" then
          output = output .. ","
        end
      end

      if s.textNode and not s.textNodeStart then
        local subNode = input:match("^%s*<(%w+)", pos) or input:match("^%s*{(%w+)", pos)
        if not s.isTag and not subNode and not var then
          s.textNodeStart = not s.textNodeStart
          output = output .. ", [["
        end
      end

      output = output .. tok
      pos = pos + 1
    else
      if not s.textNode and not s.deepString and not s.deepStringApos then
        s.textNode = not s.textNode
        if s.textNode then
          local subNode = input:match("%s*<(%w+)", pos)
          local trail = input:sub(pos - 10, pos):gsub("[%s\r\n]", "")
          if s.isTag and not subNode then
            if trail:sub(#trail, #trail) ~= ">" then
              output = output .. "}, [["
            end
          elseif s.deepNode > 0 and not subNode then
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
  -- print("===================")
  -- print(transformedCode)
  -- print("===================")
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
