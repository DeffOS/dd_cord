local type = type
local format = string.format
local error = error
local MsgN = MsgN

module("ddcord")

function FormatTypeAssert(pos,expect,got)
	format("bad argument #%i (%s expected, got %s)",pos,expect,type(got))
end
function FormatFuncMsg(name,...)
	return name .. " - " .. format(...)
end

function TypeAssert(pos,var,expect)
	if type(var) == expect then return end
	error(FormatTypeAssert(pos,expect,t),2)
end

function CreateFuncAssert(name)
	local formFunc = function(...)
		return FormatFuncMsg(name,...)
	end
	return function(cond,msg,...)
		if cond then return end
		error(formFunc(msg,...),2)
	end
end

function CreateFuncWarn(name)
	local formFunc = function(...)
		return FormatFuncMsg(name,...)
	end
	return function(cond,msg,...)
		if cond then return end
		MsgN(formFunc(msg,...))
		return true
	end
end

function CreateFuncMsg(name)
	local formFunc = function(...)
		return FormatFuncMsg(name,...)
	end
	return function(msg,...)
		MsgN(formFunc(msg,...))
	end
end