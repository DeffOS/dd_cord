local function allowed(ply)
	return ply:IsSuperAdmin() and ply:IsFullyAuthenticated()
end

do
	concommand.Add("cdscan",function(ply,cmd,args,argstr)
		if !allowed(ply) then return end
		local path = args[1] or ""
		local gamePath = args[2] or "GAME"
		if path != "" and !(string.EndsWith( path, "/" ) or string.EndsWith( path, "\\" )) then
			path = path .. "/"
		end
		local files,dirs = file.Find(path .. "*",gamePath)
		if dirs then
			for _, dir in ipairs(dirs) do
				MsgN(path .. dir .. "/")
			end
		end
		if files then
			for _, fl in ipairs(files) do
				MsgN(path .. fl)
			end
		end
	end)
end

if SERVER then
    concommand.Add("require",function(ply,cmd,args)
        if !allowed(ply) then return end
        require(args[1])
    end)

	concommand.Add("print",function(ply,cmd,args,argstr)
		if !allowed(ply) then return end
		RunString("print(" .. argstr .. ")", "ddcord.ServerPrintCommand", true )
	end)
	concommand.Add("PrintTable",function(ply,cmd,args,argstr)
		if !allowed(ply) then return end
		RunString("var=" .. argstr .. " PrintTable(var)", "ddcord.ServerPrintTableCommand", true )
	end)
else
	concommand.Add("print_cl",function(ply,cmd,args,argstr)
		if !allowed(ply) then return end
		RunString("print(" .. argstr .. ")", "ddcord.ClientPrintCommand", true )
	end)
	concommand.Add("PrintTable_cl",function(ply,cmd,args,argstr)
		if !allowed(ply) then return end
		RunString("var=" .. argstr .. " PrintTable(var)", "ddcord.ClientPrintTableCommand", true )
	end)
end