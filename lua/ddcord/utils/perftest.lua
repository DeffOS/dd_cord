local SysTime = SysTime
local print = print
local assert = assert

module("ddcord.perftest")
local _time = 0
local _started = false

function Start()
	if started then
		ErrorNoHalt("DDCORD - Preftest already started,continuing...\n")
	end
	_started = true
	_time = SysTime()
end

function Spew(str)
	diff = SysTime() - _time
	_time = SysTime()
	print(str .. ":", diff)
end

function End(spew)
	assert(_started,"DDCORD - Perftest is not started!")
	if spew then Spew(spew) end
	_started = false
	_time = 0
end