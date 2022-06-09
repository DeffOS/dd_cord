AddCSLuaFile()
ENT.Type = "anim"

if true then return end
print("AAAAAAAAAAAA")
if CLIENT then
	local TMatrix = Matrix()
	local TMaterial = Material("vgui/white")
	local render_SetMaterial,cam_PushModelMatrix,cam_PopModelMatrix =
		render.SetMaterial,cam.PushModelMatrix,cam.PopModelMatrix
	function ENT:Draw()
		local time = SysTime()
		for i = 1,10000,1 do
			cam_PushModelMatrix(TMatrix)
			cam_PopModelMatrix()
		end
		print(SysTime() - time)
		time = SysTime()
		for i = 1,10000,1 do
			render_SetMaterial(TMaterial)
		end
		print(SysTime() - time)
		self.Draw = nil
	end
else
	hook.Add("InitPostEntity","DDCORD_SpawnTestEnt",function()
		local ent = ents.Create("ent_ddtester")
		ent:Spawn()
	end)
end