if SERVER then return end
local PLAYER = FindMetaTable("Player")
local NULL_FUNC = NULL_FUNC
local _KeysToName = {"KEY_0","KEY_1","KEY_2","KEY_3","KEY_4","KEY_5","KEY_6","KEY_7","KEY_8","KEY_9","KEY_A","KEY_B","KEY_C","KEY_D","KEY_E","KEY_F","KEY_G","KEY_H","KEY_I","KEY_J","KEY_K","KEY_L","KEY_M","KEY_N","KEY_O","KEY_P","KEY_Q","KEY_R","KEY_S","KEY_T","KEY_U","KEY_V","KEY_W","KEY_X","KEY_Y","KEY_Z","KEY_PAD_0","KEY_PAD_1","KEY_PAD_2","KEY_PAD_3","KEY_PAD_4","KEY_PAD_5","KEY_PAD_6","KEY_PAD_7","KEY_PAD_8","KEY_PAD_9","KEY_PAD_DIVIDE","KEY_PAD_MULTIPLY","KEY_PAD_MINUS","KEY_PAD_PLUS","KEY_PAD_ENTER","KEY_PAD_DECIMAL","KEY_LBRACKET","KEY_RBRACKET","KEY_SEMICOLON","KEY_APOSTROPHE","KEY_BACKQUOTE","KEY_COMMA","KEY_PERIOD","KEY_SLASH","KEY_BACKSLASH","KEY_MINUS","KEY_EQUAL","KEY_ENTER","KEY_SPACE","KEY_BACKSPACE","KEY_TAB","KEY_CAPSLOCK","KEY_NUMLOCK","KEY_ESCAPE","KEY_SCROLLLOCK","KEY_INSERT","KEY_DELETE","KEY_HOME","KEY_END","KEY_PAGEUP","KEY_PAGEDOWN","KEY_BREAK","KEY_LSHIFT","KEY_RSHIFT","KEY_LALT","KEY_RALT","KEY_LCONTROL","KEY_RCONTROL","KEY_LWIN","KEY_RWIN","KEY_APP","KEY_UP","KEY_LEFT","KEY_DOWN","KEY_RIGHT","KEY_F1","KEY_F2","KEY_F3","KEY_F4","KEY_F5","KEY_F6","KEY_F7","KEY_F8","KEY_F9","KEY_F10","KEY_F11","KEY_F12","KEY_CAPSLOCKTOGGLE","KEY_NUMLOCKTOGGLE","KEY_SCROLLLOCKTOGGLE","MOUSE_LEFT","MOUSE_RIGHT","MOUSE_MIDDLE","MOUSE_4","MOUSE_5","MOUSE_WHEEL_UP","MOUSE_WHEEL_DOWN"}
local function _GetKeyName(key)
	return _KeysToName[key] or "UNKNOWN"
end
local function _ProcessBindDown(self,key)
	(self["_dd_keybinds_in"][key] or NULL_FUNC)(self)
end
local function _ProcessBindUp(self,key)
	(self["_dd_keybinds_out"][key] or NULL_FUNC)(self)
end

function PLAYER:GetKeyState(key)
	return tobool(self["_dd_keys_state"][key])
end

function PLAYER:GetBind(key,state)
	return self[state and "_dd_keybinds_out" or "_dd_keybinds_in"][key]
end
function PLAYER:AddBind(key,func,state)
	state = state and "_dd_keybinds_out" or "_dd_keybinds_in"
	if self[state][key] then
		ErrorNoHalt(ddcord.FormatFuncMsg("PLAYER:AddBind","Cant add bind to [%s], key already occupied!",_GetKeyName(key)))
		return
	end
	self[state][key] = func
end
function PLAYER:RemoveBind(key,state)
	self[state and "_dd_keybinds_out" or "_dd_keybinds_in"][key] = nil
end

hook.Add("PlayerInitialSpawn","ddcord.Binds.PlayerInitialSpawn",function(ply)
	ply["_dd_keys_state"] = {}
	ply["_dd_keybinds_in"] = {}
	ply["_dd_keybinds_out"] = {}
end)
hook.Add("PlayerButtonDown","ddcord.Binds.PlayerKeyDown",function(ply,key)
	if !ply["_dd_keys_state"] then return end
	ply["_dd_keys_state"][key] = true
	_ProcessBindDown(ply,key)
end)
hook.Add("PlayerButtonUp","ddcord.Binds.PlayerKeyUp",function(ply,key)
	if !ply["_dd_keys_state"] then return end
	ply["_dd_keys_state"][key] = false
	_ProcessBindUp(ply,key)
end)

concommand.Add("ddcord_keystates",function(ply)
	timer.Simple(2,function()
		local str = "BUTTON TOGGLED FOR " .. ply:Nick() .. " :\n"
		for key,state in pairs(ply["_dd_keys_state"]) do
			if state == false then continue end
			str = str .. "\t" .. _GetKeyName(key) .. "\n"
		end
		print(str)
	end)
end)