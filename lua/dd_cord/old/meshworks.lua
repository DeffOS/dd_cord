local tableInsert = table.insert
local ipairs = ipairs
local Vector = Vector
local VECTOR = FindMetaTable("Vector")
local Vec_eq = VECTOR.__eq

// PSA: If some numbnut tries to manipulate noncopy model caches of those objects remember - you the one shooting your own foot

do // Collision Handler - Could be used as separate part for collision usage only
	local Cache = DD_CORD.CollisionCache or {}
	DD_CORD.CollisionCache = Cache

	function DD_CORD:ClearCollisionCache()
		Cache = {}
		self.CollisionCache = Cache
	end

	local HANDMETA = {}
	HANDMETA["__index"] = HANDMETA
	local COLLMETA = {}
	COLLMETA["__index"] = COLLMETA

	do // Initialization
		local _PreInitQuotaList = {}
		local _PreInitCacheQuota = {["__list"] = _PreInitQuotaList}
		local _CleanupConvexes do
			local function _VecIsExists(tab,vec)
				for __,check in ipairs(tab) do
					if vec[1]==check[1] and vec[2]==check[2] and vec[3]==check[3] then
						return true
					end
				end
				return false
			end
			_CleanupConvexes = function(convexes)
				local final = {}
				for _,_mesh in ipairs(convexes) do
					local convex = {}
					for _,vert in ipairs(_mesh) do
						local pos = vert["pos"]
						if !_VecIsExists(convex,pos) then
							tableInsert(convex,pos)
						end
					end
					tableInsert(final,convex)
				end
				//print("Cleaned "..tostring(#final).." convexes")
				return final
			end
		end
		local function _BuildMeshBuffers(_mesh)
			local indices = {}
			local vertices = {}
			local vertscheck = {}
			for _,vert in ipairs(_mesh) do
				local pos = vert["pos"]
				local ind
				for __,check in ipairs(vertscheck) do
					if Vec_eq(pos,check) then
						ind = __
						break
					end
				end
				if !ind then
					tableInsert(vertices,vert)
					tableInsert(vertscheck,pos)
					ind = #vertscheck
				end
				tableInsert(indices,ind)
			end
			return {["Vertices"]=vertices,["Indices"]=indices}
		end
		local _CreateDummy = SERVER and function(model)
			local ent = ents.Create(util.IsValidRagdoll(model) and "prop_ragdoll" or "prop_dynamic")
			ent:AddEFlags(EFL_SERVER_ONLY)
			ent:SetModel(model)
			ent:Spawn()
			return ent
		end or function(model)
			return (util.IsValidRagdoll(model) and ClientsideRagdoll or ents.CreateClientProp)(model)
		end

		local _PreInitCacher = function(model)
			if _PreInitQuotaList[model] then return end
			table.insert(_PreInitCacheQuota,model)
			_PreInitQuotaList[model] = true
		end
		local _PostInitCacher = function(model,force)
			if Cache[model] and !force then return end
			util.PrecacheModel(model)
			assert(util.IsValidModel(model),"DD_CORD: Cant load invalid model")
			local Objects = {}
			local ent = _CreateDummy(model)
			for i=0,ent:GetPhysicsObjectCount()-1 do
				local phys = ent:GetPhysicsObjectNum(i)
				local Convexes = _CleanupConvexes(phys:GetMeshConvexes())
				local CollMesh = _BuildMeshBuffers(phys:GetMesh())
				local CollObj = setmetatable({
					["IsCopy"] = false,
					["ConvexCount"] = #Convexes,
					["Convexes"] = Convexes,
					["Mesh"] = CollMesh
				},COLLMETA)
				//if CLIENT then // NOTE: Idk why bother with visual mesh when vcollide_wireframe exists
				//	local _mesh = Mesh()
				//	_mesh:BuildFromTriangles(Convexes)
				//	CollObj["Mesh"] = _mesh
				//end
				Objects[i+1] = CollObj
			end
			ent:Remove()
			Cache[model] = setmetatable(Objects,HANDMETA)
		end
		if GAMEMODE then
			DD_CORD.PrecacheCollision = _PostInitCacher
		else
			DD_CORD.PrecacheCollision = _PreInitCacher
		end
		hook.Add("InitPostEntity","DDCORD_InitilizeCollisionCaching",function()
			for _,model in ipairs(_PreInitCacheQuota) do
				_PostInitCacher(model,true)
			end
			DD_CORD.PrecacheCollision = _PostInitCacher
		end)
	end

	function DD_CORD.GetCollisionObject(model)
		if !Cache[model] then DD_CORD.PrecacheCollision(model) end
		return Cache[model]
	end
	do // Meta Functions
		function HANDMETA:GetRawConvexes(num)
			// NOTE: This passes reference - messing with it is bad idea
			return self[num]["Convexes"]
		end

		function HANDMETA:GetConvexes(num,matrix)
			local convexes = self[num]["Convexes"]
			local final = {}
			if matrix then
				for _,convex in ipairs(convexes) do
					local finalconvex = {}
					for ind,vec in ipairs(convex) do
						finalconvex[ind] = matrix*vec
					end
					tableInsert(final,finalconvex)
				end
			else
				for _,convex in ipairs(convexes) do
					local finalconvex = {}
					for ind,vec in ipairs(convex) do
						finalconvex[ind] = Vector(vec)
					end
					tableInsert(final,finalconvex)
				end
			end
			return final
		end

		function HANDMETA:AddConvexes(collision,num,matrix)
			local convexes = self[num]["Convexes"]
			if matrix then
				for _,convex in ipairs(convexes) do
					local finalconvex = {}
					for ind,vec in ipairs(convex) do
						finalconvex[ind] = matrix*vec
					end
					tableInsert(collision,finalconvex)
				end
			else
				for _,convex in ipairs(convexes) do
					local finalconvex = {}
					for ind,vec in ipairs(convex) do
						finalconvex[ind] = Vector(vec)
					end
					tableInsert(collision,finalconvex)
				end
			end
		end

		function HANDMETA:GetCollMesh(num,matrix)
			local buffers = self[num]["Mesh"]
			local vertbuffer = {}
			local finalmesh = {}
			if matrix then
				for _,vec in ipairs(buffers["Vertices"]) do
					vertbuffer[_] = {pos=matrix*vec}
				end
			else
				for _,vec in ipairs(buffers["Vertices"]) do
					vertbuffer[_] = {pos=Vector(vec)}
				end
			end
			for _,index in ipairs(buffers["Indices"]) do
				finalmesh[_] = vertbuffer[index]
			end
			return finalmesh
		end

		function HANDMETA:AddCollMesh(collision,num,matrix)
			local buffers = self[num]["Mesh"]
			local vertbuffer = {}
			if matrix then
				for _,vec in ipairs(buffers["Vertices"]) do
					vertbuffer[_] = {pos=matrix*vec}
				end
			else
				for _,vec in ipairs(buffers["Vertices"]) do
					vertbuffer[_] = {pos=Vector(vec)}
				end
			end
			for _,index in ipairs(buffers["Indices"]) do
				tableInsert(target,vertbuffer[index])
			end
		end
	end
end

if CLIENT then // Mesh Handler
	local EngineCache = DD_CORD.MeshCache and DD_CORD.MeshCache["EngineCache"] or {}
	local CustomCache = DD_CORD.MeshCache and DD_CORD.MeshCache["CustomCache"] or {}
	DD_CORD.MeshCache = {["EngineCache"] = EngineCache,["CustomCache"] = CustomCache}

	function DD_CORD:ClearMeshCache()
		EngineCache = {}
		CustomCache = {}
		self.MeshCache["EngineCache"] = EngineCache
		self.MeshCache["CustomCache"] = CustomCache
	end

	local MESHMETA = {}
	MESHMETA["__index"] = MESHMETA

	do
		local function _BuildVisMeshBuffers(_mesh)
			local indices = {}
			local verts = {}
			local vertcheck = {}
			for _,vert in ipairs(_mesh) do
				local ind = vertcheck[vert] // util.GetModelMeshes already affiliates vertex data with triangles so we will abuse such a present
				if !ind then
					tableInsert(verts,vert)
					ind = #verts
					vertcheck[vert] = ind
				end
				tableInsert(indices,ind)
			end
			return {["Vertices"]=verts,["Indices"]=indices}
		end
		function DD_CORD.PrecacheMesh(model)
			if PathCache[model] then return end
			assert(util.IsValidModel(model),"DD_CORD: Cant load invalid model")
			local materials = {}
			local buffers = {}
			local meshes = {}
			local final = setmetatable({
				["IsCopy"] = false,
				["PartsCount"] = 0,
				["Materials"] = materials,
				["Buffers"] = buffers,
				["Meshes"] = meshes
			},MESHMETA)
			local MeshSoup = util.GetModelMeshes(model)
			for _,mesh in ipairs(MeshSoup) do
				tableInsert(materials,Material(mesh["material"]))
				tableInsert(buffers,_BuildVisMeshBuffers(mesh["triangles"]))
				local _mesh = Mesh()
				_mesh:BuildFromTriangles(mesh["triangles"])
				tableInsert(meshes,_mesh)
			end
			final["PartsCount"] = #materials
			EngineCache[model] = final
		end
	end

	function DD_CORD.GetMeshObject(model)
		if !EngineCache[model] then DD_CORD.PrecacheMesh(model) end
		return EngineCache[model]
	end

	do
		function MESHMETA:Draw()
			for i=1,self["PartsCount"],1 do
				render.SetMaterial(self["Materials"][i])
				self["Meshes"][i]:Draw()
			end
		end
		function MESHMETA:DrawInPosition(matrix)
			cam.PushModelMatrix(matrix)
				for i=1,self["PartsCount"],1 do
					render.SetMaterial(self["Materials"][i])
					self["Meshes"][i]:Draw()
				end
			cam.PopModelMatrix()
		end
	end
end

do // Model Object
	local MODELMETA = {}
	MODELMETA["__index"] = MODELMETA
	function DD_CORD.CreateModelObject(model,matrix)
		assert(util.IsValidModel(model),"DD_CORD: Cant load invalid model")
		matrix = matrix or Matrix()
		local res = setmetatable({
			["Collision"] = {},
			["Models"] = {},
			["Matrix"] = matrix
		},MODELMETA)
	end
end

do // Scene Object
	
end