-- Hunter Tools: Server
-- Der Server entscheidet, wer Jäger ist. Nur Jäger bekommen die Positionen der anderen übertragen.

util.AddNetworkString("HT_SetESP")
util.AddNetworkString("HT_Chaser")

local CV = HunterTools.CV

local function SetHunter(ply, state)
	ply:SetNWBool("HT_Hunter", state)
	if not state then
		ply:SetNWBool("HT_ESP", false)
		ply:SetNWFloat("HT_ChaserUntil", 0)
	end
	-- Alle sehen im Chat, wer Jäger ist.
	PrintMessage(HUD_PRINTTALK, "[Hunter] " .. ply:Nick() .. (state and " ist jetzt der Jäger." or " ist nicht mehr der Jäger."))
end
HunterTools.SetHunter = SetHunter

local function FindPlayer(query)
	query = string.lower(query)
	for _, ply in ipairs(player.GetAll()) do
		if string.lower(ply:SteamID()) == query then return ply end
	end
	for _, ply in ipairs(player.GetAll()) do
		if string.find(string.lower(ply:Nick()), query, 1, true) then return ply end
	end
end

-- ht_sethunter <name|steamid|^> [1/0]    (^ = du selbst)
concommand.Add("ht_sethunter", function(caller, _, args)
	local function reply(msg)
		if IsValid(caller) then caller:ChatPrint(msg) else print(msg) end
	end

	if IsValid(caller) and not caller:IsSuperAdmin() then
		reply("[Hunter] Nur Superadmins dürfen den Jäger festlegen.")
		return
	end

	local query = args[1]
	if not query or query == "" then
		reply("[Hunter] Benutzung: ht_sethunter <name|steamid|^> [1/0]")
		return
	end

	local target = (query == "^" and IsValid(caller)) and caller or FindPlayer(query)
	if not IsValid(target) then
		reply("[Hunter] Spieler nicht gefunden: " .. query)
		return
	end

	SetHunter(target, args[2] ~= "0")
end)

hook.Add("PlayerInitialSpawn", "HT_AdminHunter", function(ply)
	-- Kurz warten, damit Admin-Mods (ULX etc.) die Usergroup gesetzt haben.
	timer.Simple(3, function()
		if IsValid(ply) and CV.adminsAreHunters:GetBool() and ply:IsAdmin() then
			SetHunter(ply, true)
		end
	end)
end)

net.Receive("HT_SetESP", function(_, ply)
	local on = net.ReadBool()
	if on and not (HunterTools.IsHunter(ply) and CV.allowESP:GetBool()) then return end
	ply:SetNWBool("HT_ESP", on)
end)

net.Receive("HT_Chaser", function(_, ply)
	local radius = net.ReadUInt(16)
	local duration = net.ReadFloat()

	if not HunterTools.IsHunter(ply) or not CV.allowChaser:GetBool() then return end

	local now = CurTime()
	if ply:GetNWFloat("HT_ChaserReady", 0) > now then return end

	radius = math.Clamp(radius, 100, CV.chaserMaxRadius:GetFloat())
	duration = math.Clamp(duration, 1, CV.chaserMaxTime:GetFloat())

	ply:SetNWFloat("HT_ChaserRadius", radius)
	ply:SetNWFloat("HT_ChaserUntil", now + duration)
	ply:SetNWFloat("HT_ChaserReady", now + duration + CV.chaserCooldown:GetFloat())
end)

-- Spieler hinter Wänden werden normalerweise nicht übertragen (PVS).
-- Für den Jäger fügen wir ihre Positionen hinzu, solange Radar oder Chaser aktiv ist.
hook.Add("SetupPlayerVisibility", "HT_PVS", function(ply)
	if not HunterTools.IsHunter(ply) then return end

	local esp = ply:GetNWBool("HT_ESP", false) and CV.allowESP:GetBool()
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
