-- Correto
local version = "Lua 5.3"
if _VERSION ~= version then
  io.stderr:write("\nThis test suite is for ", version, ", not for ", _VERSION,
    "\nExiting tests\n")
  return
end

print(arg)
_G._ARG._arg = 1

-- _soft = rawget(_G, "_soft") or false
