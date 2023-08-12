if SERVER then
    util.AddNetworkString("ddcord.NetReady")
    local PLAYER = FindMetaTable("Player")
    function PLAYER:IsNetLoaded() return self["dd_b_netloded"] end
    net.Receive("ddcord.NetReady",function(_,ply)
    	if ply:IsNetLoaded() then return end
    	ply["dd_b_netloded"] = true
    	hook.Run("ddcord.NetReady",ply)
    end)
else
    hook.Add("InitPostEntity","ddcord.NetReady",function() net.Start("ddcord.NetReady") net.SendToServer() end)
end

local Compress = util.Compress
local Decompress = util.Decompress
local TableToJSON = util.TableToJSON
local JSONToTable = util.JSONToTable
local Vector = Vector
local isvector = isvector

module("net")

function WriteCompressedTable(tab)
    local data = Compress(TableToJSON(tab))
    local len = #data
    WriteUInt(len,16)
    WriteData(data,len)
    return len
end
function ReadCompressedTable()
    local len = ReadUInt(16)
    return JSONToTable(Decompress(ReadData(len))),len
end
function PokeChannel(channel,ply)
	Start(channel)
	if SERVER then
		Send(ply)
	else
		SendToServer()
	end
end

function WriteIntVector(vec,bits)
	WriteInt(vec[1],bits)
	WriteInt(vec[2],bits)
	WriteInt(vec[3],bits)
end
function ReadIntVector(bits,vec)
	if isvector(vec) then
		vec:SetUnpacked(ReadInt(bits),ReadInt(bits),ReadInt(bits))
	else
		vec = Vector(ReadInt(bits),ReadInt(bits),ReadInt(bits))
	end
	return vec
end

function WriteUIntVector(vec,bits)
	WriteUInt(vec[1],bits)
	WriteUInt(vec[2],bits)
	WriteUInt(vec[3],bits)
end
function ReadUIntVector(bits,vec)
	if isvector(vec) then
		vec:SetUnpacked(ReadUInt(bits),ReadUInt(bits),ReadUInt(bits))
	else
		vec = Vector(ReadUInt(bits),ReadUInt(bits),ReadUInt(bits))
	end
	return vec
end