local type = type
local format = string.format
local error = error
local MsgN = MsgN

module("ddcord")

function FormatTypeAssert(pos,expect,got)
	return format("bad argument #%i (%s expected, got %s)",pos,expect,type(got))
end

function TypeAssert(pos,var,expect)
	if type(var) == expect then return end
	error(FormatTypeAssert(pos,expect,t),2)
end

function FuncNamedAssert(condition,name,form,...)
	if condition then return end
	error(name .. " - " .. format(form,...),2)
end

function CreateFuncAssert(name)
	local formFunc = function(...)
		return name .. " - " .. format(...)
	end
	return function(cond,msg,...)
		if cond then return end
		error(formFunc(msg,...),2)
	end, function(cond,msg,...)
		if cond then return end
		MsgN(formFunc(msg,...))
		return true
	end
end