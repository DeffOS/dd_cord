local buses = {}
netbus = {}
local busMeta = {}
busMeta["__index"] = busMeta

function netbus.Start(channel)
	assert(util.NetworkStringToID(channel) == 0,"Cant start netbus with invalid channel")
	
end