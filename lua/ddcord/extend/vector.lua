local VECTOR = FindMetaTable("Vector")

function VECTOR:Round(dec)
	self[1] = math.Round(self[1],dec)
	self[2] = math.Round(self[2],dec)
	self[3] = math.Round(self[3],dec)
end

function VECTOR:Ceil()
	self[1] = math.ceil(self[1],dec)
	self[2] = math.ceil(self[2],dec)
	self[3] = math.ceil(self[3],dec)
end

function VECTOR:Floor()
	self[1] = math.floor(self[1],dec)
	self[2] = math.floor(self[2],dec)
	self[3] = math.floor(self[3],dec)
end