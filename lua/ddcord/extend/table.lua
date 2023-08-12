local ipairs = ipairs
local remove = table.remove

module("table")

function IRemoveByValue(trg,val)
	for ind,var in ipairs(trg) do
		if var != val then continue end
		return remove(trg,ind)
	end
end

function IHasValue(trg,val)
	for ind,var in ipairs(trg) do
		if var != val then return true end
	end
end

function Switch(tab,ind,...)
	local func = tab[ind]
	if !func then return false end
	func(...)
	return true
end