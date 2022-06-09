local tableInsert = table.insert

function includeCL(file) file = file .. ".lua" if SERVER then AddCSLuaFile(file) else include(file) end end
function includeSV(file) file = file .. ".lua" if SERVER then include(file) end end
function includeSH(file) file = file .. ".lua" if SERVER then AddCSLuaFile(file) end include(file) end
function NULL_FUNC() end

do
    local _Settings = {
        tagcolor = Color(0,220,128),
        realmed = true,
    }
    local _RealmColor = SERVER and Color(136, 221, 255) or Color(255, 221, 102)
    local _RealmTag = SERVER and "SERVER" or "CLIENT"
    local _uCol = Color(0,0,0)
    local _nCol = Color(220,220,220)
    local _wCol = Color(220,64,64)
    local _eCol = Color(255,64,255)
    function DD_CORD.CreateMessangers(name,color,namespace)
        local msg,war,err =
        function(...)
            MsgC(_uCol,"[",color,name,_uCol,"] : ",_RealmColor,...)
        end,
        function(...)
            MsgC(_wCol,"[",color,name,_wCol,"] : ",_RealmColor,_RealmTag,_wCol,...)
        end,
        function(halt,...)
            if halt then
                local res = "["..name.."] : "
                for _,arg in ipairs({...}) do
                    res = res.." "..tostring(arg)
                end
            else
                ErrorNoHalt("["..name.."] : ",...)
            end
        end
        if istable(namespace) then namespace.Message=msg namespace.Warning=war namespace.Error=err end
        return msg,war,err
    end
end

do
    // DD_CORD.BuildMatrix("Yes",{4,4})
    function DD_CORD.BuildMatrix(var,size)
        if !isfunction(var) then
            local variable = var or "NONE"
            var = function()
                return variable
            end
        end
        local indextable = {}
        local matrix = {}
        local depth = #size
        local curind = {}
        local function depthCrawler(mat,ldepth)
            if (ldepth == depth) then
                for i = 1, size[ldepth],1 do
                    local cell = var(curind)
                    table.insert(indextable,{pos = table.Copy(curind),data = cell})
                    curind[ldepth] = i
                    mat[i] = cell
                end
            else
                for i = 1, size[ldepth],1 do
                    local nmat = {}
                    mat[i] = nmat
                    depthCrawler(nmat,ldepth + 1)
                end
            end
        end
        depthCrawler(matrix,1)
        return matrix,indextable
    end
    do local function FinalizeKeyValues(values)
            local final = {}
            local collapsekeys = {}
            for _,pack in ipairs(values) do
                local key = pack["Key"]
                local value = pack["Value"]
                value = istable(value) and FinalizeKeyValues(value) or value
                local finalvalue = final[key]
                if finalvalue then
                    if collapsekeys[key] then
                        tableInsert(finalvalue,value)
                    else
                        collapsekeys[key] = true
                        final[key] = {finalvalue,value}
                    end
                else
                    final[key] = value
                end
            end
            return final
        end
        DD_CORD.FinalizeKeyValues = FinalizeKeyValues
    end
end

do
    function DD_CORD.CreateMetatable() local t={} t["__index"]=t return t end
    DD_CORD.METAS = DD_CORD.METAS or {}
    do
    	local Metas = DD_CORD.METAS
    	function DD_CORD.CreateClassMetatable(name)
    		name = string.upper(name)
    		if Metas[name] then return Metas[name] end
    		local newmeta = DD_CORD.CreateMetatable()
    		Metas[name] = newmeta
    		return newmeta
    	end
        function DD_CORD.CopyClassMetatable(base,name)
    		base,name = string.upper(base),string.upper(name)
    		if Metas[name] then return Metas[name] end
            if !Matas[base] then error("Cant copy non-existant class metatable [",tostring(base),"] for [",tostring(name),"]\n") return end
    		local newmeta = DD_CORD.CreateMetatable()
            for ind,var in pairs(Matas[base]) do
                newmeta[ind] = var
            end
    		Metas[name] = newmeta
    		return newmeta
    	end
    	function DD_CORD.GetClassMetatable(name)
    		name = string.upper(name)
    		return Metas[name]
    	end
    end
    function DD_CORD:BuildEnviroment(namespace,customspace)
        local env = {}
        for _,name in ipairs(namespace) do
            local func = _G[name]
            if !func then continue end
            env[name] = func
        end
        if istable(customspace) then
            for index,variable in ipairs(customspace) do
                env[index] = variable
            end
        end
        return env
    end
end

if SERVER then
    concommand.Add("require",function(ply,cmd,args)
        if !ply:IsSuperAdmin() then return end
        require(args[1])
    end)
else
    local SCREEN_PROCENT
    local function _updateSize()
        SCREEN_PROCENT = (ScrW() < ScrH() and ScrW() or ScrH() ) / 100
    end
    _updateSize()
    hook.Add("OnScreenSizeChanged","DD_CORD_UpdateScreenSize",_updateSize)
    function GetScreenUnit() return SCREEN_PROCENT end
    function GetScreenScale(p) return SCREEN_PROCENT * p end
end

local function _SterializeCon(args)
    local strargs = ""
    for _,str in ipairs(args) do
        strargs = strargs .. " " .. str
    end
    return strargs
end
concommand.Add("print",function(ply,cmd,args)
    if !ply:IsSuperAdmin() then return end
    local funcstring = _SterializeCon(args)
    RunString("print(" .. funcstring .. ")", "DD_PrintCommand", true )
end)
concommand.Add("PrintTable",function(ply,cmd,args)
    if !ply:IsSuperAdmin() then return end
    local funcstring = _SterializeCon(args)
    RunString("var=" .. funcstring .. " PrintTable(var)", "DD_PrintTableCommand", true )
end)