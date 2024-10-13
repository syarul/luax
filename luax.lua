local h = require('h')

local originalRequire = require

local function resetTable(store, data)
  for key, value in pairs(data) do
    -- ignore output and pos
    if key ~= "output" and key ~= "pos" then
      store[key] = value
    end
  end
end

local State = {}
State.__index = State

function State:new()
  return setmetatable({
    output = "",
    pos = 1,
    deepNode = 0,
    deepString = false,
    deepStringApos = false,
    isTag = false,
    textNode = false,
    textNodeStart = false
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

local function decentParserAST(input)
  local var = false
  local s = State:new()
  local resetStore = {}
  resetTable(resetStore, s)
  local varStore = {}

  while s.pos <= #input do
    local tok = input:sub(s.pos, s.pos)
    -- simple decent parser
    -- escape " ' encapsulation
    -- opening tag
    if tok == "<" and s:notStr() then
      local nextSpacingPos = input:find("%s", s.pos)
      local tagRange = input:sub(s.pos, nextSpacingPos)
      local tagName = tagRange:match("<(%w+)", 0)
      local tagNameEnd = tagRange:match("</(%w+)>", 0)
      if tagName then s:incDeepNode() end
      s:inc()

      if tagName and not s.deepString then
        s:toggle("isTag", true)
        s:toggle("textNode", false)
        if s.textNodeStart then
          s:toggle("textNodeStart")
          s:conc("]]")
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
          else
            s:conc(")")
          end
        end
        s:inc(#tagNameEnd + 2)
      else
        s:conc(tok, 1)
      end
    elseif tok == '"' and s:xml() then
      s:toggle("deepString")
      s:conc(tok, 1)
    elseif tok == "'" and s:xml() then
      s:toggle("deepStringApos")
      s:conc(tok, 1)
    elseif tok == ">" and s:xml() and s:notStr() then
      if not s.textNode and s.isTag and input:sub(s.pos - 1, s.pos - 1) ~= "/" then
        s:toggle("isTag")
        s:toggle("textNode")
        s:conc("}")
      else
        s.isTag = not s.isTag
        s:decDeepNode()
        s:conc("})")
      end
      s:inc()
    elseif tok == "/" and input:sub(s.pos + 1, s.pos + 1) == ">" and s:notStr() then
      s:decDeepNode()
      s:conc("})")
      s:inc(2)
    elseif tok == "{" and s:xml() and s:notStr() then
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
    elseif tok == "}" and var then
      var = not var
      if not var then
        -- restore currentState from snapshot
        resetTable(s, varStore)
      end
      s:inc()
    elseif s:xml() and s:notStr() then
      if tok:match("%s") then
        if not var and s.isTag and s.output:sub(-1) ~= "{" and s.output:sub(-1) == "\"" or
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
  return s.output
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
