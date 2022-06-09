netbus = {}
local busQuota = {}
local busMeta = {}
busMeta["__index"] = busMeta

local CurrentBus = nil

function netbus.Start(channel)
	assert(util.NetworkStringToID(channel) == 0,"Cant start netbus with invalid channel")
	
end