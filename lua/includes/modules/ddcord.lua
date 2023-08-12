AddCSLuaFile()
local function shared(file)
	file = format("ddcord/%s.lua",file)
	AddCSLuaFile(file)
	include(file)
end
local function server(file)
	if CLIENT then return end
	file = format("ddcord/%s.lua",file)
	include(file)
end

shared("misc")

shared("utils/_manifest_")
shared("extend/_manifest_")