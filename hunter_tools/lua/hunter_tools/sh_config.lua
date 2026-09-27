-- Hunter Tools: Gemeinsame Einstellungen (Server + Client)
-- Server-ConVars legen die Obergrenzen fest; der Jäger kann im Menü nur innerhalb davon einstellen.

HunterTools = HunterTools or {}

local SV_FLAGS = { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }

HunterTools.CV = {
	allowAim         = CreateConVar("ht_allow_aim", "1", SV_FLAGS, "Aim-Hilfe für den Jäger erlauben", 0, 1),
	allowESP         = CreateConVar("ht_allow_esp", "1", SV_FLAGS, "Radar (alle durch Wände sehen) für den Jäger erlauben", 0, 1),
	allowChaser      = CreateConVar("ht_allow_chaser", "1", SV_FLAGS, "Chaser-Modus (Wärmebild-Puls) erlauben", 0, 1),
	aimMaxStrength   = CreateConVar("ht_aim_max_strength", "0.6", SV_FLAGS, "Maximale Stärke der Aim-Hilfe (0-1)", 0, 1),
	aimMaxFov        = CreateConVar("ht_aim_max_fov", "15", SV_FLAGS, "Maximaler Aim-Hilfe-Winkel in Grad", 1, 45),
	chaserMaxRadius  = CreateConVar("ht_chaser_max_radius", "3000", SV_FLAGS, "Maximaler Chaser-Radius in Units", 100, 20000),
	chaserMaxTime    = CreateConVar("ht_chaser_max_duration", "10", SV_FLAGS, "Maximale Chaser-Dauer in Sekunden", 1, 60),
	chaserCooldown   = CreateConVar("ht_chaser_cooldown", "15", SV_FLAGS, "Abklingzeit nach einem Chaser-Puls in Sekunden", 0, 600),
	adminsAreHunters = CreateConVar("ht_admins_are_hunters", "0", SV_FLAGS, "Admins werden beim Joinen automatisch Jäger", 0, 1),
}

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
