-- Hunter Tools: Server
-- Der Server entscheidet, wer Jäger ist. Nur Jäger bekommen die Positionen der anderen übertragen.

util.AddNetworkString("HT_Set")
util.AddNetworkString("HT_Ability")
util.AddNetworkString("HT_Roared")
util.AddNetworkString("HT_Ping")
util.AddNetworkString("HT_Tracks")
util.AddNetworkString("HT_Heart")
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

------------------------------------------------------------------------
-- Fähigkeiten mit Abklingzeit (Chaser, Brüllen, Teleport)
------------------------------------------------------------------------

local ROAR_SOUND = "npc/fast_zombie/fz_scream1.wav"
local TELEPORT_SOUND = "npc/stalker/go_alert2a.wav"

-- Sucht entlang der Blickrichtung einen freien Platz, an dem der Jäger stehen kann.
local function FindTeleportSpot(ply)
	local eye = ply:EyePos()
	local aim = ply:GetAimVector()
	local tr = util.TraceLine({
		start = eye,
		endpos = eye + aim * CV.teleportRange:GetFloat(),
		filter = ply,
		mask = MASK_PLAYERSOLID,
	})
	if tr.HitSky then return end

	local mins, maxs = ply:GetHull()
	local dest = tr.HitPos + tr.HitNormal * 2

	for i = 0, 12 do
		local candidate = dest - aim * (i * 16)
		local down = util.TraceHull({
			start = candidate + Vector(0, 0, 8),
			endpos = candidate - Vector(0, 0, 64),
			mins = mins, maxs = maxs, filter = ply, mask = MASK_PLAYERSOLID,
		})
		if not down.StartSolid then
			local free = util.TraceHull({
				start = down.HitPos, endpos = down.HitPos,
				mins = mins, maxs = maxs, filter = ply, mask = MASK_PLAYERSOLID,
			})
			if not free.Hit then return down.HitPos end
		end
	end
end

local Abilities = {
	chaser = {
		allow = CV.allowChaser, ready = "HT_ChaserReady",
		run = function(ply, now)
			local duration = HunterTools.Get(ply, "HT_ChaserCfgTime")
			ply:SetNWFloat("HT_ChaserRadius", HunterTools.Get(ply, "HT_ChaserCfgRadius"))
			ply:SetNWFloat("HT_ChaserUntil", now + duration)
			return duration + CV.chaserCooldown:GetFloat()
		end,
	},

	roar = {
		allow = CV.allowRoar, ready = "HT_RoarReady",
		run = function(ply, now)
			ply:EmitSound(ROAR_SOUND, 120, 80, 1, CHAN_VOICE)

			local duration = CV.roarDuration:GetFloat()
			local radiusSqr = CV.roarRadius:GetFloat() ^ 2
			local origin = ply:GetPos()
			local victims = {}
			for _, target in ipairs(player.GetAll()) do
				if HunterTools.IsTarget(ply, target) and origin:DistToSqr(target:GetPos()) <= radiusSqr then
					target:SetNWFloat("HT_SlowFactor", CV.roarSlow:GetFloat())
					target:SetNWFloat("HT_SlowUntil", now + duration)
					victims[#victims + 1] = target
				end
			end

			if #victims > 0 then
				net.Start("HT_Roared")
				net.WriteFloat(duration)
				net.Send(victims)
			end
			return CV.roarCooldown:GetFloat()
		end,
	},

	teleport = {
		allow = CV.allowTeleport, ready = "HT_TeleportReady",
		run = function(ply)
			local spot = FindTeleportSpot(ply)
			if not spot then
				ply:ChatPrint("[Hunter] Dort ist kein Platz zum Teleportieren.")
				return
			end
			ply:EmitSound(TELEPORT_SOUND, 75, 70)
			ply:SetPos(spot)
			ply:SetVelocity(-ply:GetVelocity())
			ply:ScreenFade(SCREENFADE.IN, color_black, 0.4, 0)
			sound.Play(TELEPORT_SOUND, spot, 80, 60)
			return CV.teleportCooldown:GetFloat()
		end,
	},
}

net.Receive("HT_Ability", function(_, ply)
	local name = HunterTools.Abilities[net.ReadUInt(4)]
	local ability = Abilities[name]
	if not ability or not HunterTools.IsHunter(ply) or not ply:Alive() then return end
	if not ability.allow:GetBool() then return end

	local now = CurTime()
	if ply:GetNWFloat(ability.ready, 0) > now then return end

	local cooldown = ability.run(ply, now)
	if cooldown then ply:SetNWFloat(ability.ready, now + cooldown) end
end)

------------------------------------------------------------------------
-- Sinne: Geräusch-Radar, Fußspuren, Herzschlag
------------------------------------------------------------------------

-- Jäger, die einen bestimmten Sinn eingeschaltet haben
local function HuntersWith(key, allow)
	local list = {}
	if not allow:GetBool() then return list end
	for _, ply in ipairs(player.GetAll()) do
		if HunterTools.IsHunter(ply) and ply:Alive() and HunterTools.Get(ply, key) then
			list[#list + 1] = ply
		end
	end
	return list
end

local NOISE_SPRINT, NOISE_JUMP, NOISE_SHOT = 1, 2, 3
local lastNoise = {}

local function MakeNoise(ply, kind)
	local now = CurTime()
	if (lastNoise[ply] or 0) > now - 0.6 then return end
	lastNoise[ply] = now

	local pos = ply:GetPos()
	local radiusSqr = CV.noiseRadius:GetFloat() ^ 2
	for _, hunter in ipairs(HuntersWith("HT_NoiseOn", CV.allowNoise)) do
		if HunterTools.IsTarget(hunter, ply) and hunter:GetPos():DistToSqr(pos) <= radiusSqr then
			net.Start("HT_Ping")
			net.WriteVector(pos + Vector(0, 0, 40))
			net.WriteUInt(kind, 2)
			net.Send(hunter)
		end
	end
end

hook.Add("KeyPress", "HT_NoiseJump", function(ply, key)
	if key == IN_JUMP and ply:OnGround() then MakeNoise(ply, NOISE_JUMP) end
end)

hook.Add("EntityFireBullets", "HT_NoiseShot", function(ent)
	if IsValid(ent) and ent:IsPlayer() then MakeNoise(ent, NOISE_SHOT) end
end)

local lastPrint = {}

timer.Create("HT_SensesTick", 0.25, 0, function()
	local trackers = HuntersWith("HT_TracksOn", CV.allowTracks)
	local listeners = HuntersWith("HT_HeartOn", CV.allowHeart)
	local prints = {}

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and not HunterTools.IsHunter(ply) and ply:GetObserverMode() == OBS_MODE_NONE then
			local vel = ply:GetVelocity()

			-- Sprinten ist laut, Gehen und Schleichen nicht
			if ply:OnGround() and ply:KeyDown(IN_SPEED) and not ply:Crouching() and vel:Length2DSqr() > 180 ^ 2 then
				MakeNoise(ply, NOISE_SPRINT)
			end

			-- Alle ~36 Units einen Fußabdruck, abwechselnd links und rechts
			if #trackers > 0 and ply:OnGround() then
				local pos = ply:GetPos()
				local last = lastPrint[ply]
				if not last or last.pos:DistToSqr(pos) > 36 ^ 2 then
					local left = not (last and last.left)
					lastPrint[ply] = { pos = pos, left = left }
					prints[#prints + 1] = { ply = ply, pos = pos, yaw = vel:Angle().y, left = left }
				end
			end
		end
	end

	if #prints > 0 then
		local radiusSqr = CV.tracksRadius:GetFloat() ^ 2
		for _, hunter in ipairs(trackers) do
			local origin, mine = hunter:GetPos(), {}
			for _, p in ipairs(prints) do
				if p.ply ~= hunter and HunterTools.IsTarget(hunter, p.ply) and origin:DistToSqr(p.pos) <= radiusSqr then
					mine[#mine + 1] = p
				end
			end
			if #mine > 0 then
				net.Start("HT_Tracks")
				net.WriteUInt(math.min(#mine, 255), 8)
				for i = 1, math.min(#mine, 255) do
					net.WriteVector(mine[i].pos)
					net.WriteFloat(mine[i].yaw)
					net.WriteBool(mine[i].left)
				end
				net.Send(hunter)
			end
		end
	end

	-- Herzschlag: nur die Entfernung zum nächsten Opfer, keine Richtung
	for _, hunter in ipairs(listeners) do
		local origin, nearest = hunter:GetPos(), -1
		for _, target in ipairs(player.GetAll()) do
			if HunterTools.IsTarget(hunter, target) then
				local d = origin:Distance(target:GetPos())
				if nearest < 0 or d < nearest then nearest = d end
			end
		end
		net.Start("HT_Heart")
		net.WriteFloat(nearest)
		net.Send(hunter)
	end

	-- Opfer-Herzklopfen: Entfernung zum nächsten Jäger
	if CV.victimHeart:GetBool() then
		local hunters = {}
		for _, ply in ipairs(player.GetAll()) do
			if HunterTools.IsHunter(ply) and ply:Alive() then hunters[#hunters + 1] = ply end
		end
		if #hunters > 0 then
			for _, victim in ipairs(player.GetAll()) do
				local nearest = -1
				for _, hunter in ipairs(hunters) do
					if HunterTools.IsTarget(hunter, victim) then
						local d = hunter:GetPos():Distance(victim:GetPos())
						if nearest < 0 or d < nearest then nearest = d end
					end
				end
				if nearest >= 0 then
					net.Start("HT_Heart")
					net.WriteFloat(nearest)
					net.Send(victim)
				end
			end
		end
	end
end)

hook.Add("PlayerDisconnected", "HT_Cleanup", function(ply)
	lastNoise[ply] = nil
	lastPrint[ply] = nil
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
