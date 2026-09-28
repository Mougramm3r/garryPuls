-- PULSE: loader (runs on server and client)

if SERVER then
	AddCSLuaFile("pulse/sh_config.lua")
	AddCSLuaFile("pulse/sh_pills.lua")
	AddCSLuaFile("pulse/cl_hunter.lua")
	AddCSLuaFile("pulse/cl_menu.lua")
	AddCSLuaFile("pulse/cl_atmosphere.lua")

	include("pulse/sh_config.lua")
	include("pulse/sh_pills.lua")
	include("pulse/sv_hunter.lua")
	include("pulse/sv_game.lua")
else
	include("pulse/sh_config.lua")
	include("pulse/sh_pills.lua")
	include("pulse/cl_hunter.lua")
	include("pulse/cl_menu.lua")
	include("pulse/cl_atmosphere.lua")
end
