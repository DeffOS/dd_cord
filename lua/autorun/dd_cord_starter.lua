local function _Load(file) file = "dd_cord/" .. file .. ".lua" AddCSLuaFile(file) include(file) end
local function _LoadSV(file) if CLIENT then return end file = "dd_cord/" .. file .. ".lua" include(file) end
DD_CORD = DD_CORD or {}
_Load("tier0")
//_LoadSV("binds")
_LoadSV("netbus")
_Load("tier1")
//_Load("meshworks")