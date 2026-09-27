-- Hunter Tools: Gemeinsame Einstellungen (Server + Client)
-- Server-ConVars legen die Obergrenzen fest; die Jäger-Einstellungen liegen pro Spieler auf dem Server.

HunterTools = HunterTools or {}

local SV_FLAGS = { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }

HunterTools.CV = {
	allowAim         = CreateConVar("ht_allow_aim", "1", SV_FLAGS, "Aim-Hilfe für den Jäger erlauben", 0, 1),
	allowESP         = CreateConVar("ht_allow_esp", "1", SV_FLAGS, "Radar (alle durch Wände sehen) für den Jäger erlauben", 0, 1),
	allowChaser      = CreateConVar("ht_allow_chaser", "1", SV_FLAGS, "Chaser-Modus (Wärmebild-Puls) erlauben", 0, 1),
	multiHunter      = CreateConVar("ht_multi_hunter", "0", SV_FLAGS, "Mehrere Jäger gleichzeitig erlauben", 0, 1),
	aimMaxStrength   = CreateConVar("ht_aim_max_strength", "0.8", SV_FLAGS, "Maximale Stärke der Aim-Hilfe (0-1)", 0, 1),
	aimMaxFov        = CreateConVar("ht_aim_max_fov", "20", SV_FLAGS, "Maximaler Aim-Hilfe-Winkel in Grad", 1, 45),
	chaserMaxRadius  = CreateConVar("ht_chaser_max_radius", "3000", SV_FLAGS, "Maximaler Chaser-Radius in Units", 100, 20000),
	chaserMaxTime    = CreateConVar("ht_chaser_max_duration", "10", SV_FLAGS, "Maximale Chaser-Dauer in Sekunden", 1, 60),
	chaserCooldown   = CreateConVar("ht_chaser_cooldown", "15", SV_FLAGS, "Abklingzeit nach einem Chaser-Puls in Sekunden", 0, 600),
	adminsAreHunters = CreateConVar("ht_admins_are_hunters", "0", SV_FLAGS, "Admins werden beim Joinen automatisch Jäger", 0, 1),
}

local CV = HunterTools.CV

local function Fixed(v) return function() return v end end
local function Limit(cvar) return function() return cvar:GetFloat() end end

-- Einstellungen pro Jäger. Sie liegen als NW-Werte auf dem Spieler, damit Admins sie im Menü ändern können.
HunterTools.Settings = {
	{ key = "HT_AimOn",           type = "bool",  default = false },
	{ key = "HT_AimOnFire",       type = "bool",  default = false },
	{ key = "HT_AimNPC",          type = "bool",  default = false },
	{ key = "HT_AimStrength",     type = "float", default = 0.5,  min = 0,   max = Limit(CV.aimMaxStrength) },
	{ key = "HT_AimFov",          type = "float", default = 12,   min = 1,   max = Limit(CV.aimMaxFov) },
	{ key = "HT_ESP",             type = "bool",  default = false },
	{ key = "HT_ESPNames",        type = "bool",  default = true },
	{ key = "HT_ChaserCfgRadius", type = "float", default = 1500, min = 100, max = Limit(CV.chaserMaxRadius) },
	{ key = "HT_ChaserCfgTime",   type = "float", default = 5,    min = 1,   max = Limit(CV.chaserMaxTime) },
}

HunterTools.SettingByKey = {}
for _, s in ipairs(HunterTools.Settings) do
	s.max = s.max or Fixed(1)
	HunterTools.SettingByKey[s.key] = s
end

-- Liest eine Jäger-Einstellung, immer innerhalb der aktuellen Server-Grenzen.
function HunterTools.Get(ply, key)
	local s = HunterTools.SettingByKey[key]
	if s.type == "bool" then
		return ply:GetNWBool(key, s.default)
	end
	return math.Clamp(ply:GetNWFloat(key, s.default), s.min, math.max(s.min, s.max()))
end

-- Wer darf den Jäger festlegen und die Einstellungen anderer ändern? (Host / Superadmin)
function HunterTools.IsManager(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() or ply:IsSuperAdmin() then return true end
	return SERVER and ply:IsListenServerHost() or false
end

function HunterTools.IsHunter(ply)
	return IsValid(ply) and ply:GetNWBool("HT_Hunter", false)
end

-- Gültiges Ziel für den Jäger: lebender Spieler, der nicht selbst Jäger ist.
function HunterTools.IsTarget(hunter, ply)
	return IsValid(ply) and ply ~= hunter and ply:Alive()
		and not HunterTools.IsHunter(ply)
		and ply:GetObserverMode() == OBS_MODE_NONE
end

function HunterTools.ChaserActive(ply)
	return ply:GetNWFloat("HT_ChaserUntil", 0) > CurTime()
end
