local band = bit.band
local insert = table.insert
local istable = istable
local ipairs = ipairs
local ScrW = ScrW
local ScrH = ScrH

module("ddcord")

function HasBit(byte,bt)
	return band(byte,bt) == bt
end
function BuildRadialHull(rad)
	return Vector(-rad,-rad,-rad),Vector(rad,rad,rad)
end
function BuildCylindricalHull(rad,bot,top)
	if isvector(rad) then
		rad,bot,top = rad:Unpack()
	end
	return Vector(-rad,-rad,bot),Vector(rad,rad,top)
end

function FinalizeKeyValues(values)
	local final = {}
	local collapsekeys = {}
	for _,pack in ipairs(values) do
		local key = pack["Key"]
		local value = pack["Value"]
		value = istable(value) and FinalizeKeyValues(value) or value
		local finalvalue = final[key]
		if finalvalue then
			if collapsekeys[key] then
				insert(finalvalue,value)
			else
				collapsekeys[key] = true
				final[key] = {finalvalue,value}
			end
		else
			final[key] = value
		end
	end
	return final
end

if SERVER then return end

local SCREEN_PROCENT
local function _updateSize()
	SCREEN_PROCENT = (ScrW() < ScrH() and ScrW() or ScrH() ) / 100
end
_updateSize()
hook.Add("OnScreenSizeChanged","ddcord.UpdateScreenSize",_updateSize)
function GetScreenUnit() return SCREEN_PROCENT end
function GetScreenScale(p) return SCREEN_PROCENT * p end