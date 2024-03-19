local TypeAssert = ddcord.TypeAssert
local FormatTypeAssert = ddcord.FormatTypeAssert
local insert = table.insert
local format = string.format

module("dmesh",package.seeall)
META = META or {__name="DynMesh"}
META.__index = META

function Create(data)
	TypeAssert(1,data,"table")
	assert(data[1] != nil,"bad argument #%i (mesh table has no primitives!)")
	local class = {}
	for pid, dataprim in ipairs(data) do
		if !dataprim.material then continue end
		local indices = {}
		local vertices = {}
		local triangles = {}
		do // Solves indices/vertices from triangles
			local solver = {}
			for ind, vertex in ipairs(dataprim) do
				if solver[vertex] then
					insert(indices,solver[vertex])
				else
					local vind = insert(vertices,vertex)
					insert(indices,vind)
					solver[vertex] = vind
				end
				triangles[ind] = vertex
			end
		end
		insert(class,{
			indices = indices,
			vertices = vertices,
			triangles = triangles,
			material = Material(dataprim.material)
		})
	end
	assert(class[1] != nil,"failed to load any primitives!")
	setmetatable(class,META)
	class:RecalculateBounds()
	return class
end

do
	local _iterator
	function META:IterateVertices()
		return _iterator,{PrimitiveInd = 1,VertexInd = 0,Vertices = self[1].vertices,Self = self}
	end
	function _iterator(state)
		state.VertexInd = state.VertexInd + 1
		local value = state.Vertices[state.VertexInd]
		if !value then
			state.VertexInd = 1
			state.PrimitiveInd = state.PrimitiveInd + 1
			local primitive = state.Self[state.PrimitiveInd]
			if primitive then
				state.Vertices = primitive.vertices
				return state.VertexInd,state.PrimitiveInd,state.Vertices[state.VertexInd]
			end
			return
		end
		return state.VertexInd,state.ConvexInd,value
	end
end

function META:__tostring() return format("DynMesh: %p",self) end

do
	local VECTOR = FindMetaTable("Vector")
	// TODO: For Negation/Matrix-multiplication rotate normals as well
	local Negate = VECTOR.Negate
	function META:Negate()
		self._dirty = true
		for _,__,vert in self:IterateVertices() do Negate(vert.pos) end
	end
	local Add = VECTOR.Add
	function META:Add(vec)
		TypeAssert(1,vec,"Vector")
		self._dirty = true
		for _,__,vert in self:IterateVertices() do Add(vert.pos,vec) end
	end
	local Sub = VECTOR.Sub
	function META:Sub(vec)
		TypeAssert(1,vec,"Vector")
		self._dirty = true
		for _,__,vert in self:IterateVertices() do Sub(vert.pos,vec) end
	end
	local Mul = VECTOR.Mul
	function META:Mul(vec)
		local t = type(vec)
		assert(t == "Vector" or t == "VMatrix",FormatTypeAssert(1,"Vector or VMatrix",type(vec)))
		self._dirty = true
		for _,__,vert in self:IterateVertices() do Mul(vert.pos,vec) end
	end
	local Div = VECTOR.Div
	function META:Div(vec)
		TypeAssert(1,vec,"Vector")
		self._dirty = true
		for _,__,vert in self:IterateVertices() do Div(vert.pos,vec) end
	end
end
function META:Append(append)
	assert(getmetatable(append) == META,FormatTypeAssert(1,"DynMesh",type(append)))
	assert(self != append,"[DMesh] Cant append to myself! Or you wonna crash?")
	self._dirty = true
	// TODO: Merge same-material primitives
	for _, primitive in ipairs(append) do
		table.insert(self,primitive)
	end
	self:RecalculateBounds()
end

do
	function removeByValue(tbl,val)
		for key, value in ipairs(tbl) do
			if value != val then continue end
			table.remove(tbl,key)
			return key
		end
	end
	function META:ConvertToCollisionMesh()
		if !cmesh or !cmesh.META then return end
		local result = {}
		for _, primitive in ipairs(self) do
			local indices = primitive.indices
			local parts = {}
			local vpinds = {}
			for i = 1, #indices, 3 do
				local v1,v2,v3 = indices[i],indices[i+1],indices[i+2]
				local p1,p2,p3 = vpinds[v1],vpinds[v2],vpinds[v3]
				local dominant = p1 or p2 or p3
				if !dominant then
					dominant = {}
					table.insert(parts,dominant)
				end
				if p1 then
					if p1 != dominant then
						for _, vid in ipairs(p1) do
							vpinds[vid] = dominant
							table.insert(dominant,vid)
							removeByValue(parts,p1)
						end
					end
				else
					vpinds[v1] = dominant
					table.insert(dominant,v1)
				end
				if p2 then
					if p2 != dominant then
						for _, vid in ipairs(p2) do
							vpinds[vid] = dominant
							table.insert(dominant,vid)
							removeByValue(parts,p2)
						end
					end
				else
					vpinds[v2] = dominant
					table.insert(dominant,v2)
				end
				if p3 then
					if p3 != dominant then
						for _, vid in ipairs(p3) do
							vpinds[vid] = dominant
							table.insert(dominant,vid)
							removeByValue(parts,p3)
						end
					end
				else
					vpinds[v3] = dominant
					table.insert(dominant,v3)
				end
			end
			local vertices = primitive.vertices
			for _, part in ipairs(parts) do
				for ind, vind in ipairs(part) do
					part[ind] = Vector(vertices[vind].pos)
				end
			end
			table.Add(result,parts)
		end
		result.count = #result
		setmetatable(result,cmesh.META)
		return result
	end
end

function META:GetBounds()
	return self.Min,self.Max
end

function META:RecalculateBounds()
	local minx,miny,minz,maxx,maxy,maxz = math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge
	for _, primitive in ipairs(self) do
		for __,vertex in ipairs(primitive.vertices) do
			local x,y,z = vertex.pos:Unpack()
			if x < minx then minx = x elseif x > maxx then maxx = x end
			if y < miny then miny = y elseif y > maxy then maxy = y end
			if z < minz then minz = z elseif z > maxz then maxz = z end
		end
	end
	self.Min,self.Max = Vector(minx,miny,minz),Vector(maxx,maxy,maxz)
end

if SERVER then return end

function META:RebuildMeshes(force)
	if !self._dirty and !force then return end
	Msg(format("[DMesh] Building mesh for %s\n",tostring(self)))
	for _, primitive in ipairs(self) do
		local iMesh = Mesh(primitive.material)
		iMesh:BuildFromTriangles(primitive.triangles)
		primitive.Mesh = iMesh
		local stackmesh = {Mesh = iMesh,Material = primitive.material}
		primitive._rendermesh = function() return stackmesh end
	end
	self._dirty = false
end

function META:Draw(mode)
	if self._dirty then self:RebuildMeshes() end
	for _, primitive in ipairs(self) do
		if !primitive._enabled then continue end
		primitive.Mesh:Draw(mode)
	end
end

function META:DrawEntity(ent,mode)
	if self._dirty then self:RebuildMeshes() end
	local _oRenderMesh = ent.GetRenderMesh
	for _, primitive in ipairs(self) do
		if !primitive._enabled then continue end
		ent.GetRenderMesh = primitive._rendermesh
		ent:DrawModel(mode)
	end
	ent.GetRenderMesh = _oRenderMesh
end