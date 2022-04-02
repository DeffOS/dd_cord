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
    local _eCol = Color(255,64,255)
    // DD_CORD:CreateMessanger("DD_TEST",{tagcolor = Color(79,255,25),realmed = false},Color(160,160,0),Color(0,0,0))
    function DD_CORD:CreateMessanger(name,settings,...)
        table.Inherit(settings,_Settings)
        local tagcolor = settings["tagcolor"]
        local colors = {...}
        if settings["realmed"] then
            return function(...)
                local args = {...}
                for _,var in ipairs(args) do
                    if isnumber(var) then
                        args[_] = colors[var] or _eCol
                    else
                        args[_] = args[_] .. " "
                    end
                end
                table.insert(args,_RealmColor) // Set Realm color for "developer 1" top-left log
                table.insert(args,"\n")
                MsgC(_uCol,"[",_RealmColor,_RealmTag,_uCol,"] [",tagcolor,name,_uCol,"]: ",unpack(args))
            end
        else
            return function(...)
                local args = {...}
                for _,var in ipairs(args) do
                    if isnumber(var) then
                        args[_] = colors[var] or _eCol
                    else
                        args[_] = args[_] .. " "
                    end
                end
                table.insert(args,"\n")
                MsgC(_uCol,"[",tagcolor,name,_uCol,"]: ",unpack(args))
            end
        end
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
end

do
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