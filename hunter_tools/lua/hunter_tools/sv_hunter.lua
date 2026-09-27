-- Hunter Tools: Server
-- Der Server entscheidet, wer Jäger ist. Nur Jäger bekommen die Positionen der anderen übertragen.

util.AddNetworkString("HT_Set")
util.AddNetworkString("HT_Chaser")
util.AddNetworkString("HT_AdminSetHunter")
util.AddNetworkString("HT_AdminSetCVar")

local CV = HunterTools.CV

local function ClearHunter(ply)
	ply:SetNWBool("HT_Hunter", false)
	ply:SetNWFloat("HT_ChaserUntil", 0)
	PrintMessage(HUD_PRINTTALK, "[Hunter] " .. ply:Nick() .. " ist nicht mehr der Jäger.")
end

local function SetHunter(ply, state)
	if HunterTools.IsHunter(ply) == state then return end
	if not state then
		ClearHunter(ply)
		return
	end

	-- Nur ein Jäger erlaubt: bisherigen Jäger ablösen
	if not CV.multiHunter:GetBool() then
		for _, other in ipairs(player.GetAll()) do
			if other ~= ply and HunterTools.IsHunter(other) then ClearHunter(other) end
		end
	end

	ply:SetNWBool("HT_Hunter", true)
	-- Alle sehen im Chat, wer Jäger ist.
	PrintMessage(HUD_PRINTTALK, "[Hunter] " .. ply:Nick() .. " ist jetzt der Jäger.")
end
HunterTools.SetHunter = SetHunter

-- Wird "mehrere Jäger" ausgeschaltet, bleibt nur der erste Jäger übrig.
cvars.AddChangeCallback("ht_multi_hunter", function(_, _, new)
	if new ~= "0" then return end
	local kept = false
	for _, ply in ipairs(player.GetAll()) do
		if HunterTools.IsHunter(ply) then
			if kept then ClearHunter(ply) else kept = true end
		end
	end
end, "HT_Multi")

hook.Add("PlayerInitialSpawn", "HT_Join", function(ply)
	-- Kurz warten, damit Admin-Mods (ULX etc.) die Usergroup gesetzt haben.
	timer.Simple(5, function()
		if not IsValid(ply) then return end
		if CV.adminsAreHunters:GetBool() and ply:IsAdmin() then
			SetHunter(ply, true)
		end
		if HunterTools.IsManager(ply) then
			ply:ChatPrint("[Hunter] Hunter Tools geladen. Drücke F5 für das Menü.")
		end
	end)
end)

-- Menü: Host/Superadmin macht einen Spieler zum Jäger (oder nimmt es zurück)
net.Receive("HT_AdminSetHunter", function(_, ply)
	local target = net.ReadEntity()
	local state = net.ReadBool()
	if not HunterTools.IsManager(ply) then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	SetHunter(target, state)
end)

-- Menü: Host/Superadmin ändert eine Server-Einstellung
local editable = {}
for _, cv in pairs(CV) do editable[cv:GetName()] = cv end

net.Receive("HT_AdminSetCVar", function(_, ply)
	local name = net.ReadString()
	local value = net.ReadFloat()
	if not HunterTools.IsManager(ply) then return end
	local cv = editable[name]
	if not cv then return end
	value = math.Clamp(value, cv:GetMin() or value, cv:GetMax() or value)
	RunConsoleCommand(name, tostring(value))
end)

-- Jäger-Einstellung ändern: für sich selbst, oder als Host/Superadmin für andere
net.Receive("HT_Set", function(_, ply)
	local target = net.ReadEntity()
	local key = net.ReadString()
	local value = net.ReadFloat()

	if not IsValid(target) or not target:IsPlayer() then return end
	if target ~= ply and not HunterTools.IsManager(ply) then return end

	local s = HunterTools.SettingByKey[key]
	if not s then return end

	if s.type == "bool" then
		target:SetNWBool(key, value ~= 0)
	else
		target:SetNWFloat(key, math.Clamp(value, s.min, math.max(s.min, s.max())))
	end
end)

net.Receive("HT_Chaser", function(_, ply)
	if not HunterTools.IsHunter(ply) or not CV.allowChaser:GetBool() then return end

	local now = CurTime()
	if ply:GetNWFloat("HT_ChaserReady", 0) > now then return end

	local duration = HunterTools.Get(ply, "HT_ChaserCfgTime")
	ply:SetNWFloat("HT_ChaserRadius", HunterTools.Get(ply, "HT_ChaserCfgRadius"))
	ply:SetNWFloat("HT_ChaserUntil", now + duration)
	ply:SetNWFloat("HT_ChaserReady", now + duration + CV.chaserCooldown:GetFloat())
end)

-- Spieler hinter Wänden werden normalerweise nicht übertragen (PVS).
-- Für den Jäger fügen wir ihre Positionen hinzu, solange Radar oder Chaser aktiv ist.
hook.Add("SetupPlayerVisibility", "HT_PVS", function(ply)
	if not HunterTools.IsHunter(ply) then return end

	local esp = HunterTools.Get(ply, "HT_ESP") and CV.allowESP:GetBool()
	local chaser = HunterTools.ChaserActive(ply) and CV.allowChaser:GetBool()
	if not esp and not chaser then return end

	local origin = ply:GetPos()
	local radiusSqr = ply:GetNWFloat("HT_ChaserRadius", 0) ^ 2

	for _, target in ipairs(player.GetAll()) do
		if HunterTools.IsTarget(ply, target) then
			local pos = target:GetPos()
			if esp or origin:DistToSqr(pos) <= radiusSqr then
				AddOriginToPVS(pos)
			end
		end
	end
end)
