AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Spawnable = true

if true then return end
if CLIENT then
	local mat = Material("dev/dev_interiorfloorlinoleum01f")
	function ENT:Initialize()
		//local time = SysTime()
		//local meshwork = DD_CORD.CreateMeshwork("models/player/combine_soldier_prisonguard.mdl")
		//print(SysTime()-time)
		local model = ddcord.glTF.Read("models/test.glb")
		self.Model = model
		if SERVER then return end
		local modelmesh = model:GetMesh("Cube"):GetPrimitives()[1]
		PrintTable(modelmesh.triangles)
		print(#modelmesh.triangles/3)
		local imesh = Mesh(mat)
		//imesh:BuildFromTriangles(modelmesh.triangles)
		mesh.Begin(imesh,MATERIAL_TRIANGLES,#modelmesh.triangles/3)
		for _, vertex in ipairs(modelmesh.triangles) do
			//print(_)
			mesh.Position(vertex.pos*64)
			mesh.Normal(vertex.normal)
			mesh.TexCoord(0,vertex.u,vertex.v)
			mesh.TexCoord(1,vertex.lu,vertex.lv)
			mesh.AdvanceVertex()
		end
		mesh.End()
		self.Mesh = imesh
		//self["Meshwork"] = meshwork
	end
	ENT.OnReloaded = ENT.Initialize

	local bound = Vector(-32,-32,-32)
	local wire = Material("editor/wireframe")
	function ENT:Draw()
		if !IsValid(self.Mesh) then return end
		render.SetMaterial(wire)
		render.DrawBox(Vector(),Angle(),bound,-bound,Color(255,0,0,32))
		render.SetMaterial(mat)
		self.Mesh:Draw()
	end
end