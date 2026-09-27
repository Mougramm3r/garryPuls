-- Hunter Tools: loader (runs on server and client)

if SERVER then
	AddCSLuaFile("hunter_tools/sh_config.lua")
	AddCSLuaFile("hunter_tools/cl_hunter.lua")
	AddCSLuaFile("hunter_tools/cl_menu.lua")

	include("hunter_tools/sh_config.lua")
	include("hunter_tools/sv_hunter.lua")
	include("hunter_tools/sv_game.lua")
else
	include("hunter_tools/sh_config.lua")
	include("hunter_tools/cl_hunter.lua")
	include("hunter_tools/cl_menu.lua")
end
