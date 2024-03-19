// Created by DefaultOS - DeffOS@Github, 76561198163261508@Steam
// Description: GLTFv2 barebone importer for Garry's mod.
// Note: External buffers (aka multifile GLTF) and Sparse data is not supported.
--[[
	table gltf.Read(string path) - return GLTF file with all accesors/images readed from buffers
	table gltf.Get(string path) - return cached GLTF table, tries to read if didnt find one
]]


local format = string.format
local band = bit.band
module("gltf",package.seeall)

local Cache = GetLoadedFiles and GetLoadedFiles() or {}
function GetCachedFiles()
	return table.Copy(Cache)
end

local function Open(filepath)
	assert(file.Exists(filepath,"GAME"),format("[GLTF] File (%s) doenst exist!",filepath))
	local f = file.Open(filepath,"rb","GAME")
	assert(f,"[GLTF] Failed to load file!")
	local checksum = util.CRC(f:Read())
	f:Seek(0)
	local magic,version,_length = f:ReadULong(),f:ReadULong(),f:ReadULong()
	assert(magic == 0x46546C67,"[GLTF] Provided file is not GLTF!")
	assert(version == 2,format("[GLTF] Invalid GLTF version (%s), only v2 is supported!",version))
	return f,checksum
end

local function ReadHeader(f)
	local chunkLength,chunkType = f:ReadULong(),f:ReadULong()
	assert(chunkType == 0x4E4F534A,"[GLTF] Failed to load JSON chunk!")
	local json = util.JSONToTable(f:Read(chunkLength))
	assert(json,"[GLTF] JSON table is invalid!")
	return json
end

local ReadBinary do
	local GetAccessorReader do
		local Vector = Vector
		local Matrix = Matrix
		local FILE = FindMetaTable("File")
		local ReadUByte = FILE.ReadByte
		local ReadShort = FILE.ReadShort
		local ReadUShort = FILE.ReadUShort
		local ReadULong = FILE.ReadULong
		local ReadFloat = FILE.ReadFloat
		local ReadByte = function(f)
			local b = ReadUByte(f)
			local s = band(b,127) == 127
			b = b - 127
			return s and -b or b
		end
		local CompRead = {
			[5120] = function(f) return ReadByte(f)	end,	//byte
			[5121] = function(f) return ReadUByte(f) end,	//ubyte
			[5122] = function(f) return ReadShort(f) end,	//short
			[5123] = function(f) return ReadUShort(f) end,	//ushort
			[5125] = function(f) return ReadULong(f) end,	//uint
			[5126] = function(f) return ReadFloat(f) end	//float
		}
		TypeRead = {
			["SCALAR"] = function(f,r) return r(f) end,
			["VEC2"] = function(f,r) return {r(f),r(f)} end,
			["VEC3"] = function(f,r) return Vector(r(f),r(f),r(f)) end,
			["VEC4"] = function(f,r) return {r(f),r(f),r(f),r(f)} end,
			["MAT2"] = function(f,r) return Matrix({{r(f),r(f),0,0},{r(f),r(f),0,0},{0,0,0,0},{0,0,0,0}}) end,
			["MAT3"] = function(f,r) return Matrix({{r(f),r(f),r(f),0},{r(f),r(f),r(f),0},{r(f),r(f),r(f),0},{0,0,0,0}}) end,
			["MAT4"] = function(f,r) return Matrix({{r(f),r(f),r(f),r(f)},{r(f),r(f),r(f),r(f)},{r(f),r(f),r(f),r(f)},{r(f),r(f),r(f),r(f)}}) end
		}
		GetAccessorReader = function(comp,type)
			local cfunc,tfunc = CompRead[comp],TypeRead[type]
			return function(f) return tfunc(f,cfunc) end
		end
	end
	local imageTypes = {
		["image/jpeg"] = "jpeg",
		["image/png"] = "png",
	}
	function ReadBinary(f,json)
		local _binLength,binMagic = f:ReadULong(),f:ReadULong()
		assert(binMagic == 0x004E4942,"[GLTF] Failed to load BINARY chunk!")
		assert(json.buffers[1].uri == nil,"[GLTF] External bin files are not supported!")
		assert(json.buffers[2] == nil,"[GLTF] Nughu! We are not gonna have 2 buffers!")
		local binOffset,bufferViews = f:Tell(),json.bufferViews

		if json.accessors then
			local accessors = {}
			for ind, accessor in ipairs(json.accessors) do
				assert(accessor.bufferView,"[GLTF] Sparse accessors are not supported!")
				local bufferView = bufferViews[accessor.bufferView + 1]
				f:Seek(binOffset + bufferView.byteOffset + (accessor.byteOffset or 0))
				local reader = GetAccessorReader(accessor.componentType,accessor.type)
				local result = {}
				for i = 1, accessor.count do
					result[i] = reader(f)
				end
				accessors[ind] = result
			end
			json.accessors = accessors
		end

		if json.images then
			local images = {}
			for ind, image in ipairs(json.images) do
				local bufferView = bufferViews[image.bufferView + 1]
				f:Seek(binOffset + bufferView.byteOffset)
				local result = {}
				result.data = f:Read(bufferView.byteLength)
				local type = image.mimeType
				assert(imageTypes[type],format("[GLTF] Unsupported image type (%s)!",type))
				result.filename = image.name .. "." .. imageTypes[type]
				images[ind] = result
			end
			json.images = images
		end

		json.bufferViews = nil
		json.buffers = nil
	end
end

function Read(filepath)
	local f,checksum = Open(filepath)
	if Cache[filepath] and Cache[filepath].checksum == checksum then
		return Cache[filepath]
	end
	local loadTime = SysTime()
	local json = ReadHeader(f)
	ReadBinary(f,json)
	f:Close()
	Msg(format("[GLTF]: File reading for (%s) took %f seconds.\n",filepath,SysTime() - loadTime))
	json.checksum = checksum
	Cache[filepath] = json
	return json
end

function Get(filepath)
	if Cache[filepath] then
		return Cache[filepath]
	else
		return Read(filepath)
	end
end

//concommand.Add("gltf_Test",function(ply,cmd,args)
//	local gltf = Read(args[1])
//	//PrintTable(gltf)
//end)

concommand.Add("gltf.ReadHeader",function(ply,cmd,args)
	local f = Open(args[1])
	local Json = ReadHeader(f)
	PrintTable(Json)
	f:Close()
end)