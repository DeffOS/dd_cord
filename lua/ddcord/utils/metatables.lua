
module("ddcord")
function CreateMetatable()
	local t = {}
	t.__index = t
	return t
end