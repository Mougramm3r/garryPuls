-- Hunter Tools: Loader
-- Wird automatisch auf Server und Client geladen.

if SERVER then
	AddCSLuaFile("hunter_tools/sh_config.lua")
	AddCSLuaFile("hunter_tools/cl_hunter.lua")

	include("hunter_tools/sh_config.lua")
	include("hunter_tools/sv_hunter.lua")
else
	include("hunter_tools/sh_config.lua")
	include("hunter_tools/cl_hunter.lua")
end
