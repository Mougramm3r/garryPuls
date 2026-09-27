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

	allowRoar        = CreateConVar("ht_allow_roar", "1", SV_FLAGS, "Brüllen erlauben", 0, 1),
	roarRadius       = CreateConVar("ht_roar_radius", "600", SV_FLAGS, "Brüllen: Radius in Units", 100, 3000),
	roarSlow         = CreateConVar("ht_roar_slow", "0.5", SV_FLAGS, "Brüllen: Tempo der Opfer (0.5 = halb so schnell)", 0.1, 1),
	roarDuration     = CreateConVar("ht_roar_duration", "3", SV_FLAGS, "Brüllen: Dauer der Verlangsamung in Sekunden", 0.5, 10),
	roarCooldown     = CreateConVar("ht_roar_cooldown", "30", SV_FLAGS, "Brüllen: Abklingzeit in Sekunden", 0, 600),

	allowNoise       = CreateConVar("ht_allow_noise", "1", SV_FLAGS, "Geräusch-Radar erlauben", 0, 1),
	noiseRadius      = CreateConVar("ht_noise_radius", "2500", SV_FLAGS, "Geräusch-Radar: Reichweite in Units", 200, 20000),

	allowTracks      = CreateConVar("ht_allow_tracks", "1", SV_FLAGS, "Fußspuren erlauben", 0, 1),
	tracksRadius     = CreateConVar("ht_tracks_radius", "3000", SV_FLAGS, "Fußspuren: Reichweite in Units", 200, 20000),
	tracksTime       = CreateConVar("ht_tracks_time", "8", SV_FLAGS, "Fußspuren: sichtbar für Sekunden", 1, 30),

	allowHeart       = CreateConVar("ht_allow_heart", "1", SV_FLAGS, "Herzschlag-Sensor erlauben", 0, 1),
	heartRange       = CreateConVar("ht_heart_range", "1500", SV_FLAGS, "Herzschlag: ab dieser Entfernung hörbar", 200, 5000),
	victimHeart      = CreateConVar("ht_victim_heart", "0", SV_FLAGS, "Opfer hören Herzklopfen, wenn ein Jäger in der Nähe ist", 0, 1),
	victimHeartRange = CreateConVar("ht_victim_heart_range", "1000", SV_FLAGS, "Opfer-Herzklopfen: ab dieser Entfernung zum Jäger", 200, 5000),

	allowTeleport    = CreateConVar("ht_allow_teleport", "1", SV_FLAGS, "Teleport erlauben", 0, 1),
	teleportRange    = CreateConVar("ht_teleport_range", "800", SV_FLAGS, "Teleport: maximale Reichweite in Units", 100, 5000),
	teleportCooldown = CreateConVar("ht_teleport_cooldown", "45", SV_FLAGS, "Teleport: Abklingzeit in Sekunden", 0, 600),

	-- Fähigkeiten der Opfer
	allowAdrenaline    = CreateConVar("ht_allow_adrenaline", "1", SV_FLAGS, "Opfer: Adrenalin-Sprint nach Treffer", 0, 1),
	adrenalineSpeed    = CreateConVar("ht_adrenaline_speed", "1.5", SV_FLAGS, "Adrenalin: Tempo (1.5 = 50% schneller)", 1, 3),
	adrenalineTime     = CreateConVar("ht_adrenaline_time", "3", SV_FLAGS, "Adrenalin: Dauer in Sekunden", 0.5, 10),
	adrenalineCooldown = CreateConVar("ht_adrenaline_cooldown", "20", SV_FLAGS, "Adrenalin: Abklingzeit in Sekunden", 0, 300),

	allowFlash         = CreateConVar("ht_allow_flash", "1", SV_FLAGS, "Opfer: Taschenlampen-Blitz", 0, 1),
	flashRange         = CreateConVar("ht_flash_range", "600", SV_FLAGS, "Blitz: Reichweite in Units", 100, 3000),
	flashTime          = CreateConVar("ht_flash_time", "2.5", SV_FLAGS, "Blitz: Jäger ist so lange geblendet (Sekunden)", 0.5, 10),
	flashCooldown      = CreateConVar("ht_flash_cooldown", "40", SV_FLAGS, "Blitz: Abklingzeit in Sekunden", 0, 600),

	allowSilent        = CreateConVar("ht_allow_silent", "1", SV_FLAGS, "Opfer: Leise sein", 0, 1),
	silentTime         = CreateConVar("ht_silent_time", "6", SV_FLAGS, "Leise sein: Dauer in Sekunden", 1, 30),
	silentCooldown     = CreateConVar("ht_silent_cooldown", "45", SV_FLAGS, "Leise sein: Abklingzeit in Sekunden", 0, 600),

	allowDecoy         = CreateConVar("ht_allow_decoy", "1", SV_FLAGS, "Opfer: Ablenkung werfen", 0, 1),
	decoyCooldown      = CreateConVar("ht_decoy_cooldown", "25", SV_FLAGS, "Ablenkung: Abklingzeit in Sekunden", 0, 600),

	allowHide          = CreateConVar("ht_allow_hide", "1", SV_FLAGS, "Opfer: Versteck-Bonus (still in der Hocke)", 0, 1),
	hideTime           = CreateConVar("ht_hide_time", "5", SV_FLAGS, "Versteck-Bonus: so lange still hocken (Sekunden)", 1, 30),
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
	{ key = "HT_NoiseOn",         type = "bool",  default = false },
	{ key = "HT_TracksOn",        type = "bool",  default = false },
	{ key = "HT_HeartOn",         type = "bool",  default = false },
}

-- Fähigkeiten mit Abklingzeit, die per Taste ausgelöst werden (Reihenfolge = Netzwerk-ID)
HunterTools.Abilities = { "chaser", "roar", "teleport", "flash", "silent", "decoy" }
HunterTools.VictimAbilities = { flash = true, silent = true, decoy = true }
HunterTools.AbilityID = {}
for i, name in ipairs(HunterTools.Abilities) do HunterTools.AbilityID[name] = i end

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

-- Opfer, das eine Fähigkeit nutzen darf
function HunterTools.IsVictim(ply)
	return IsValid(ply) and ply:Alive() and not HunterTools.IsHunter(ply)
		and ply:GetObserverMode() == OBS_MODE_NONE
end

-- "Leise sein": unsichtbar für Geräusch-Radar, Fußspuren und Herzschlag
function HunterTools.IsSilent(ply)
	return ply:GetNWFloat("HT_SilentUntil", 0) > CurTime()
end

-- Versteck-Bonus: unsichtbar für Chaser-Puls und Radar
function HunterTools.IsHidden(ply)
	return CV.allowHide:GetBool() and ply:GetNWBool("HT_Hidden", false)
end

-- Tempo: Brüllen macht langsamer, Adrenalin schneller (in SetupMove, damit es auch vorhergesagt wird)
hook.Add("SetupMove", "HT_Speed", function(ply, mv)
	local now, f = CurTime(), 1
	if ply:GetNWFloat("HT_SlowUntil", 0) > now then f = f * ply:GetNWFloat("HT_SlowFactor", 1) end
	if ply:GetNWFloat("HT_BoostUntil", 0) > now then f = f * ply:GetNWFloat("HT_BoostFactor", 1) end
	if f == 1 then return end
	mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * f)
	mv:SetMaxSpeed(mv:GetMaxSpeed() * f)
end)
