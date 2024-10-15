local h = require('h')

local originalRequire = require

local function resetTable(store, data)
  for key, value in pairs(data) do
    -- ignore output, pos and doctype
    if key ~= "output" and key ~= "pos" and key ~= "docType" then
      store[key] = value
    end
  end
end

local State = {}
State.__index = State

function State:new()
  return setmetatable({
    output = "",
    docType = nil,
    pos = 1,
    deepNode = 0,
    deepString = false,
    deepStringApos = false,
    isTag = false,
    textNode = false,
    textNodeStart = false,
    scriptNode = false,
    scriptNodeInit = false,
  }, self)
end

function State:incDeepNode() self.deepNode = self.deepNode + 1 end
function State:decDeepNode() self.deepNode = self.deepNode - 1 end
function State:inc(v)
  if v ~= nil then self.pos = self.pos + v else self.pos = self.pos + 1 end
end
function State:conc(val, inc)
  if type(val) == "table" then
    self.output = self.output .. table.concat(val, "")
  else
    self.output = self.output .. val
  end
  -- post processing increase token step
  if inc ~= nil then self:inc(inc) end
end
function State:xml(level)
  if level ~= nil then return self.deepNode > level end
  return self.deepNode > 0
end
function State:notStr() return not self.deepString and not self.deepStringApos end
function State:toggle(key, bool)
  if bool ~= nil then self[key] = bool else self[key] = not self[key] end
end

local function kebabToCamel(str)
  local tag = str:gsub("%-(%w)", function(c)
      return c:upper()
  end)
  local _, count = str:gsub("-", "-")
  return tag, count
end

local function formatDocTypeParams(input)
  local result = {}
  local cw = ""
  local inQuotes = false
  for i = 1, #input do
    local char = input:sub(i, i)
    if char == '"' then
      inQuotes = not inQuotes
      if cw ~= "" then
        table.insert(result, '"\\"' .. cw .. '\\""')
        cw = ""
      end
    elseif char == ' ' and not inQuotes then
      if cw ~= "" then
        table.insert(result, '"' .. cw .. '"')
        cw = ""
      end
    else
      cw = cw .. char
    end
  end
  if cw ~= "" then
    table.insert(result, '"' .. cw .. '"')
  end
  return table.concat(result, ', ')
end

local function decentParserAST(input)
  local var = false
  local s = State:new()
  local resetStore = {}
  resetTable(resetStore, s)
  local varStore = {}
  local docTypeStartPos = 0

  while s.pos <= #input do
    local tok = input:sub(s.pos, s.pos)
    -- simple decent parser
    -- escape " ' encapsulation
    -- opening tag
    if tok == "<" and s:notStr() then

      local nextSpacingPos = input:find("%s", s.pos) or input:find("%>", s.pos)
      local tagRange = input:sub(s.pos, nextSpacingPos)
      local tagName = tagRange:match("<([%w-]+)", 0)
      local tagNameEnd = tagRange:match("</([%w-]+)>", 0)
      local tagDocType = tagRange:match("<(%!%w+)", 0)
      local tagScript = tagName and tagName:match("script", 0) or tagNameEnd and tagNameEnd:match("script", 0)
      if tagDocType then
        tagName = tagDocType:sub(2)
        s.docType = true
        docTypeStartPos = s.pos + #tagDocType + 2
        s:inc()
      end
      if tagName then
        if tagName:match("(%-+)") then
          local tag, count = kebabToCamel(tagName)
          tagName = tag
          s:inc(count)
        end
        s:incDeepNode()
      end
      s:inc()

      if tagName and not s.deepString then
        s:toggle("isTag", true)
        s:toggle("textNode", false)
        if s.textNodeStart then
          s:toggle("textNodeStart")
          s:conc("]]")
        end
        if tagScript then
          s.scriptNodeInit = not s.scriptNodeInit
        end
        if s:xml(1) then
          -- handle internal return function
          local ret = input:sub(s.pos-8, s.pos):gsub("%s\r\n", ""):sub(0, 6) == "return"
          if ret then
            s:conc({tagName, "({"})
          else
            s:conc({", ", tagName, "({"})
          end
        else
          s:conc({tagName, "({"})
        end
        s:inc(#tagName)
      elseif tagNameEnd then
        if tagNameEnd:match("(%-+)") then
          local tag, count = kebabToCamel(tagNameEnd)
          tagNameEnd = tag
          s:inc(count)
        end
        s:decDeepNode()
        if s.isTag and not s.textNode then
          s:toggle("isTag")
          local trail = input:sub(0, s.pos - 2):gsub("[%s\r\n]", "")
          if trail:sub(#trail - 1, #trail - 1) == "/" then
            s:conc(")")
          else
            s:conc("})")
          end
        elseif s.isTag and s.textNode then
          s:conc("]])")
        else
          if s.textNodeStart then
            s:toggle("textNodeStart")
            s:conc("]])")
          elseif s.scriptNode then
            s:toggle("scriptNode")
            s:conc("]])")
          else
            s:conc(")")
          end
        end
        s:inc(#tagNameEnd + 2)
      else
        s:conc(tok, 1)
      end
    elseif tok == '"' and s:xml() and not s.scriptNode then
      s:toggle("deepString")
      s:conc(tok, 1)
    elseif tok == "'" and s:xml() and not s.scriptNode then
      s:toggle("deepStringApos")
      s:conc(tok, 1)
    elseif tok == ">" and s:xml() and s:notStr() then
      if not s.scriptNodeInit and not s.textNode and s.isTag and input:sub(s.pos - 1, s.pos - 1) ~= "/" then
        s:toggle("isTag")
        s:toggle("textNode")
        s:conc("}")
      elseif s.scriptNodeInit then
        s:toggle("isTag")
        s:toggle("scriptNodeInit")
        local trail = s.output:sub(#s.output - 10, #s.output):gsub("[%s\r\n]", "")
        if trail:sub(#trail) == "{" then
          s:toggle("scriptNode")
          s:conc("}, ")
        else
          s:conc("}")
        end
      else
        s.isTag = not s.isTag
        s:decDeepNode()
        s:conc("})")
      end

      if s.docType then
        s.docType = not s.docType
        local docTypeParams = s.output:sub(docTypeStartPos, s.pos - 1)
        local output = formatDocTypeParams(docTypeParams)
        s.output = s.output:sub(0, docTypeStartPos-1) .. output .. s.output:sub(s.pos)
      end
      s:inc()
    elseif tok == "/" and input:sub(s.pos + 1, s.pos + 1) == ">" and s:notStr() and not s.scriptNode then
      s:decDeepNode()
      s:conc("})")
      s:inc(2)
    elseif tok == "{" and s:xml() and s:notStr() and not s.scriptNode then
      var = not var
      if var then
        -- snapshot currentState
        resetTable(varStore, s)
        -- reset currentState
        resetTable(s, resetStore)
      end
      local trail = input:sub(s.pos - 20, s.pos-1):gsub("[%s\r\n]", "")
      if trail:sub(#trail) == ">" or trail:sub(#trail) == "}" then
        s:conc(", ")
      end
      s:inc()
    elseif tok == "}" and var and s:notStr() and not s.scriptNode then
      var = not var
      if not var then
        -- restore currentState from snapshot
        resetTable(s, varStore)
      end
      s:inc()
    elseif s:xml() and s:notStr() and not s.scriptNode then
      if tok:match("%s") then
        if not s.docType and not var and s.isTag and s.output:sub(-1) ~= "{" and s.output:sub(-1) == "\"" or
            s.isTag and input:sub(s.pos - 1, s.pos - 1) == "}" then
          s:conc(",")
        end
      end
      if s.textNode and not s.textNodeStart then
        local subNode = input:match("^%s*<(%w+)", s.pos) or input:match("^%s*{(%w+)", s.pos)
        if not s.isTag and not subNode and not var then
          s:toggle("textNodeStart")
          s:conc(", [[")
        end
      end
      s:conc(tok, 1)
    else
      if not s.textNode and s:notStr() then
        s:toggle("textNode")
        if s.textNode then
          local subNode = input:match("%s*<(%w+)", s.pos)
          local trail = input:sub(s.pos - 10, s.pos):gsub("[%s\r\n]", "")
          if s.isTag and not subNode then
            if trail:sub(#trail, #trail) ~= ">" then
              s:conc("}, [[")
            end
          elseif s:xml() and not subNode then
            s:conc("[[")
          end
        end
      end
      s:conc(tok, 1)
    end
  end
  -- this to add [] bracket to table attributes
  s.output = s.output:gsub('([%w%-_]+)%=([^%s]+)', '["%1"]=%2')
  -- encapsulate output if doctype exist
  if s.docType ~= nil then s:conc(")") end
  return s.output
end

local function preprocessLuaFile(inputFile)
  local inputCode = io.open(inputFile, "r"):read("*all")
  local transformedCode = decentParserAST(inputCode)
  -- print("===================")
  -- print(transformedCode)
  -- print("===================")
  return transformedCode
end

function _G.require(moduleName)
  local luaxFile = moduleName:gsub("%.", "/") .. ".luax"
  local luaFile
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
