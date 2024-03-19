local TypeAssert = ddcord.TypeAssert
local FormatTypeAssert = ddcord.FormatTypeAssert

module("cmesh",package.seeall)
META = META or {__name="CollMesh"}
META.__index = META

do
	local function readConvex(self,data)
		local ind = 1
		local convex = {}
		for _,pos in ipairs(data) do
			if !isvector(pos) then continue end
			convex[ind] = pos
			ind = ind + 1
		end
		convex.count = ind-1
		table.insert(self,convex)
	end
	function Create(data)
		TypeAssert(1,data,"table")
		local class = {}
		if getmetatable(data) == META then
			for convexid, convex in data:IterateConvexes() do
				local copy = {count = convex.count}
				for i = 1, convex.count do
					local vec = convex[i]
					copy[i] = Vector(vec)
				end
				class[convexid] = copy
			end
			class.count = data.count
			return setmetatable(class,META)
		end
		if istable(data[1]) then
			for _, convex in ipairs(data) do
				readConvex(class,convex)
			end
		else
			readConvex(class,data)
		end
		class.count = #class
		return setmetatable(class,META)
	end
end
do
	local _iterator
	function META:IterateVerts()
		return _iterator,{ConvexInd = 1,VertexInd = 0,Convex = self[1],Self = self}
	end
	function _iterator(state)
		state.VertexInd = state.VertexInd + 1
		local value = state.Convex[state.VertexInd]
		if !value then
			state.VertexInd = 1
			state.ConvexInd = state.ConvexInd + 1
			state.Convex = state.Self[state.ConvexInd]
			if state.Convex then
				return state.VertexInd,state.ConvexInd,state.Convex[state.VertexInd]
			end
			return
		end
		return state.VertexInd,state.ConvexInd,value
	end
end
do
	local _iterator
	function META:IterateConvexes()
		return _iterator,{Index = 0,Self = self}
	end
	function _iterator(state)
		state.Index = state.Index + 1
		local value = state.Self[state.Index]
		if !value then
			return
		end
		return state.Index,value
	end
end

function META:__tostring() return string.format("CollMesh: %p",self) end

function META:Negate()
	for _,__,pos in self:IterateVerts() do pos:Negate() end
end
function META:Add(vec)
	TypeAssert(1,vec,"Vector")
	for _,__,pos in self:IterateVerts() do pos:Add(vec) end
end
function META:Sub(vec)
	TypeAssert(1,vec,"Vector")
	for _,__,pos in self:IterateVerts() do pos:Sub(vec) end
end
function META:Mul(vec)
	local t = type(vec)
	assert(t == "Vector" or t == "VMatrix",FormatTypeAssert(1,"Vector or VMatrix",type(vec)))
	for _,__,pos in self:IterateVerts() do pos:Mul(vec) end
end
function META:Div(vec)
	TypeAssert(1,vec,"Vector")
	for _,__,pos in self:IterateVerts() do pos:Div(vec) end
end
function META:Append(append)
	assert(getmetatable(append) == META,FormatTypeAssert(1,"CollMesh",type(append)))
	assert(self != append,"[CMesh] Cant append to myself! Or you wonna crash?")
	for _, convex in append:IterateConvexes() do
		local copy = {count = convex.count}
		for i = 1, convex.count do
			local vec = convex[i]
			copy[i] = Vector(vec)
		end
		table.insert(self,copy)
		self.count = self.count + 1
	end
end

function META:GetConvex(ind) if isnumber(ind) then return self[ind] end end

function META:DebugPrint()
	MsgN(self,self.count)
	for convexind, convex in ipairs(self) do
		MsgN(string.format("[%i](%i):",convexind,convex.count))
		for _, vec in ipairs(convex) do
			MsgN(string.format("\t%s",vec))
		end
	end
end

concommand.Add("cmesh_test",function()
	local coll = Create({
		{VectorRand(-16,16),VectorRand(-16,16),VectorRand(-16,16),VectorRand(-16,16)},
		{VectorRand(-16,16),VectorRand(-16,16),VectorRand(-16,16),VectorRand(-16,16)},
	})
	local collalt = Create(coll)
	coll:Append(collalt)
	coll:DebugPrint()
end)