function getDir()
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

package.path = package.path .. ";" .. getDir() .. "/?.lua"
