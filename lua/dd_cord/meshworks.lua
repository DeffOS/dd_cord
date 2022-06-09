local tableInsert = table.insert
local ipairs = ipairs
local Vector = Vector
local VECTOR = FindMetaTable("Vector")
local VecEq = VECTOR.__eq
local FinalizeKeyValues = DD_CORD.FinalizeKeyValues

DD_CORD.Models = DD_CORD.Models or {}
local Models = DD_CORD.Models
local MODEL = DD_CORD.CreateClassMetatable("DDCORD_ModelObject")
local MESH = DD_CORD.CreateClassMetatable("DDCORD_MeshObject")
local COLL = DD_CORD.CreateClassMetatable("DDCORD_CollisionObject")

do
	local function _IsVecExists(tab,vec)
		for __,check in ipairs(tab) do
			if vec==check then
				return true
			end
		end
		return false
	end
	local CreateDummyEntity = SERVER and function(model)
		local isDynam = util.IsValidRagdoll(model)
		local ent = ents.Create(isDynam and "prop_ragdoll" or "prop_dynamic")
		ent:AddEFlags(EFL_SERVER_ONLY)
		ent:SetModel(model)
		ent:Spawn()
		return ent,isDynam
	end or function(model)
		local isDynam = util.IsValidRagdoll(model)
		local ent = (isDynam and ClientsideRagdoll or ents.CreateClientProp)(model)
		// ent:SetupBones() // FIXME: Gud jab souse - this doesnt work,needs to find way to initialize bones properly on client
		return ent,isDynam
	end

	local function CleanupConvex(convex)
		local fconvex = {}
		for _,vert in ipairs(convex) do
			local pos = vert["pos"]
			if !_IsVecExists(fconvex,pos) then
				tableInsert(fconvex,pos)
			end
		end
		return fconvex
	end
	local function BuildMeshBuffers(mesh)
		local indices = {}
		local vertices = {}

		for _,vert in ipairs(mesh) do
			local ind
			for __,check in ipairs(vertices) do
				if vert==check then
					ind = __
					break
				end
			end
			if !ind then
				tableInsert(vertices,vert)
				ind = #vertices
			end
			tableInsert(indices,ind)
		end
		return {["Vertices"]=vertices,["Indices"]=indices}
	end
	local function BuildMeshFromBuffer(buffer)
		local mesh = {}
		local verts,inds = buffer["Vertices"],buffer["Indices"]
		for vertind,ind in ipairs(inds) do
			mesh[vertind] = verts[ind]
		end
		return mesh
	end

	local function CreateMeshClass(model)
		local data = util.GetModelMeshes(model,0,0)
		local meshes = {}
		for ind,part in ipairs(data) do
			local material = Material(part["material"])
			local imesh = Mesh(material)
			imesh:BuildFromTriangles(part["triangles"])
			tableInsert(meshes,{
				["Material"] = material,
				["Buffer"] = BuildMeshBuffers(part["triangles"]),
				["IMesh"] = imesh
			})
		end
		return setmetatable(meshes,MESH)
	end
	local function CreateCollClass(dummy)
		local joints = {}
		for i = 0, dummy:GetPhysicsObjectCount()-1 do
			local phys = dummy:GetPhysicsObjectNum(i)
			local convexes = {}
			for ind,convex in ipairs(phys:GetMeshConvexes()) do
				convexes[ind] = CleanupConvex(convex)
			end
			local buffer = BuildMeshBuffers(phys:GetMesh())
			local colljoint = {
				["Convexes"] = convexes,
				["Buffer"] = buffer,
				["Mesh"] = BuildMeshFromBuffer(buffer),
			}
			joints[i+1] = colljoint
		end

		return setmetatable(joints,COLL)
	end

	local function InitModel(model,dummy,Class,isDynam)
		local Info = util.GetModelInfo(model)
		local KeyValues = FinalizeKeyValues(util.KeyValuesToTablePreserveOrder(Info.KeyValues))
		local Bones = {}
		for i = 0, dummy:GetBoneCount()-1 do
			Bones[i+1] = dummy:GetBonePosition(i)
		end

		Class["IsCopy"] = false
		Class["IsStatic"] = !isDynam
		Class["Collision"] = CreateCollClass(dummy)
		Class["SkinCount"] = Info["SkinCount"]
		Class["KeyValues"] = KeyValues
		Class["ModelValues"] = FinalizeKeyValues(util.KeyValuesToTablePreserveOrder(Info.ModelKeyValues))
		if CLIENT then Class["Visual"] = CreateMeshClass(model) end
	end

	function DD_CORD.PrecacheModel(model)
		if !util.IsValidModel(model) then return end
		//if Models[model] then return Models[model] end
		local dummy,isDynam = CreateDummyEntity(model)
		local Class = setmetatable({
			["Path"] = model
		},MODEL)
		local succ,err = pcall(InitModel,model,dummy,Class,isDynam)
		dummy:Remove()
		if succ then
			return Class
		else
			ErrorNoHalt("DD_CORD: Cant precache model ["..model.."] - "..tostring(err).."\n")
		end
	end
	print(DD_CORD.PrecacheModel("models/Lamarr.mdl"))
end

do // Model Metatable
	function MODEL:IsStatic() return self["IsStatic"] end
	function MODEL:GetVisual() return self["Visual"] end
	function MODEL:GetCollision() return self["Collision"] end
	function MODEL:__tostring()
		return "DDModel ["..self["Path"].."] ["..(self["IsStatic"] and "Prop" or "Ragdoll").."]\n\t"..tostring(self:GetCollision()).."\n\t"..tostring(self:GetVisual())
	end
end

do // Mesh Metatable
	function MESH:__tostring() return "Mesh" end
end

do // Collision Metatable
	function COLL:__tostring() return "Coll" end
end