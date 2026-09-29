-- PULSE: server side of all abilities
-- The server decides who is a hunter. Only hunters get victim positions sent to them.

local HT = Pulse
local CV = HT.CV

resource.AddFile("sound/pulse_fx/heartbeat.wav")

for _, name in ipairs({
	"HT_Set", "HT_Ability", "HT_AdminSetHunter", "HT_AdminSetCVar",
	"HT_Roared", "HT_Ping", "HT_Tracks", "HT_Heart", "HT_Blind",
	"HT_Jumpscare", "HT_ForceHeart", "HT_Blackout",
	"HT_SoundList", "HT_SoundPlay", "HT_SoundGlobal",
}) do
	util.AddNetworkString(name)
end

------------------------------------------------------------------------
-- Hunter state and loadout
------------------------------------------------------------------------

-- Which abilities the player has right now: round role, selected role or own default
function HT.RefreshLoadout(ply)
	local role, name
	if HT.InRound() then
		if ply.HT_RoundRole then role = HT.FindRole(ply.HT_RoundRole) end
		name = "Choosing..."
		if ply.HT_RoundDefault then
			ply:SetNWString("HT_Loadout", HT.Get(ply, "HT_DefLoadout"))
			ply:SetNWString("HT_RoleName", "Default")
			return
		end
	elseif ply.HT_SelectedRole then
		role = HT.FindRole(ply.HT_SelectedRole)
		if not role then ply.HT_SelectedRole = nil end
	end

	local loadout
	if role then
		loadout = role.loadout
		name = role.name
	elseif HT.InRound() then
		loadout = ""
	else
		loadout = HT.Get(ply, "HT_DefLoadout")
		name = "Default"
	end
	ply:SetNWString("HT_Loadout", loadout)
	ply:SetNWString("HT_RoleName", name)
end

-- Clears toggles, running effects and cooldowns (hunter and victim abilities)
function HT.ResetAbilityState(ply)
	for id in pairs(HT.AbilityByID) do
		ply:SetNWBool("HT_T_" .. id, false)
		ply:SetNWFloat("HT_Active_" .. id, 0)
		ply:SetNWFloat("HT_Ready_" .. id, 0)
	end
	for _, key in ipairs({ "HT_SlowUntil", "HT_BoostUntil", "HT_AdrenalineReady" }) do
		ply:SetNWFloat(key, 0)
	end
	ply:SetNWBool("HT_Hidden", false)
	ply:SetNWFloat("HT_Sanity", 100)
	ply:SetNWFloat("HT_Stamina", 100)
	ply:SetNWBool("HT_Exhausted", false)
	ply:SetNWFloat("HT_RevealUntil", 0)
	ply:SetNWFloat("HT_RootUntil", 0)
	ply:SetNWFloat("HT_HurtUntil", 0)
	ply:SetNWFloat("HT_BlackoutUntil", 0)
	ply.HT_BehindVictim = nil
	ply.HT_BehindSeen = nil
	ply:SetNWEntity("HT_BehindTarget", NULL)
	if HT.EndMimic then HT.EndMimic(ply) end
	if HT.RemoveTraps then HT.RemoveTraps(ply) end
end

-- Scare abilities and scary things lower a victim's sanity
function HT.Scare(ply, amount)
	if not CV.sanityEnabled:GetBool() or not HT.IsVictim(ply) then return end
	ply:SetNWFloat("HT_Sanity", math.Clamp(HT.Sanity(ply) - amount * CV.sanityScare:GetFloat(), 0, 100))
end

local function ChangeSanity(ply, delta)
	if not CV.sanityEnabled:GetBool() then return end
	local old = HT.Sanity(ply)
	local new = math.Clamp(old + delta, 0, 100)
	if math.abs(new - old) > 0.01 then ply:SetNWFloat("HT_Sanity", new) end
end

local function NearestVictim(hunter, maxDist)
	local best, bestDist = nil, maxDist and maxDist ^ 2 or math.huge
	local origin = hunter:GetPos()
	for _, ply in ipairs(player.GetAll()) do
		if HT.IsTarget(hunter, ply) then
			local d = origin:DistToSqr(ply:GetPos())
			if d < bestDist then best, bestDist = ply, d end
		end
	end
	return best
end

function HT.SetHunter(ply, state, quiet)
	if HT.IsHunter(ply) == state then return end
	ply:SetNWBool("HT_Hunter", state)
	HT.ResetAbilityState(ply)
	HT.RefreshLoadout(ply)
	-- character from the Pill Pack: off when no longer hunter, on for a selected role outside rounds
	if not state then
		HT.RemovePill(ply)
	elseif not HT.InRound() then
		local role = ply.HT_SelectedRole and HT.FindRole(ply.HT_SelectedRole)
		local pill = role and HT.RolePill(ply, role) or HT.Get(ply, "HT_DefPill")
		if pill ~= "" then HT.ApplyPill(ply, pill, false) end
	end
	if not quiet then
		PrintMessage(HUD_PRINTTALK, "[PULSE] " .. ply:Nick() .. (state and " is now a hunter." or " is no longer a hunter."))
	end
end

hook.Add("PlayerInitialSpawn", "HT_Join", function(ply)
	timer.Simple(5, function()
		if not IsValid(ply) then return end
		HT.RefreshLoadout(ply)
		ply:ChatPrint("[PULSE] PULSE loaded. Press F4 to open the menu.")
	end)
end)

-- Admin: make a player hunter (outside of rounds only; rounds pick hunters themselves)
net.Receive("HT_AdminSetHunter", function(_, ply)
	local target = net.ReadEntity()
	local state = net.ReadBool()
	if not HT.IsManager(ply) or HT.InRound() then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	HT.SetHunter(target, state)
end)

-- Admin: change an ability value (Server tab)
local editable = {}
for _, cv in pairs(CV) do editable[cv:GetName()] = cv end

-- Server tab values are saved in data/pulse/server.json, so they survive a crash or restart
local SERVER_FILE = "pulse/server.json"
local serverValues = util.JSONToTable(file.Read(SERVER_FILE, "DATA") or "")
local function SaveServerValues()
	file.CreateDir("pulse")
	file.Write(SERVER_FILE, util.TableToJSON(serverValues, true))
end

if not serverValues then
	-- first start with this version: new balance for Roar and sanity
	serverValues = { pulse_roar_slow = 0.75, pulse_roar_duration = 2, pulse_sanity_see = 0.5 }
	SaveServerValues()
end
if (serverValues._version or 1) < 2 then
	-- longer flashlight blind (unless the admin already set it)
	if serverValues.pulse_flash_time == nil then serverValues.pulse_flash_time = 5 end
	serverValues._version = 2
	SaveServerValues()
end
if serverValues._version < 3 then
	-- Stay Silent: new cooldown 10 s
	serverValues.pulse_silent_cooldown = 10
	serverValues._version = 3
	SaveServerValues()
end
for name, value in pairs(serverValues) do
	if editable[name] then RunConsoleCommand(name, tostring(value)) end
end

net.Receive("HT_AdminSetCVar", function(_, ply)
	local name = net.ReadString()
	local value = net.ReadFloat()
	if not HT.IsManager(ply) then return end
	local cv = editable[name]
	if not cv then return end
	value = math.Clamp(value, cv:GetMin() or value, cv:GetMax() or value)
	RunConsoleCommand(name, tostring(value))
	serverValues[name] = value
	SaveServerValues()
end)

-- Personal hunter settings: for yourself, or as admin for someone else
-- Personal settings are also saved on the server (data/pulse/players.json, per SteamID),
-- so they are back after a restart even if the game didn't save them.
local PLAYERS_FILE = "pulse/players.json"
-- keep the SteamID64 keys as text (they are too long to become numbers)
local storedSettings = util.JSONToTable(file.Read(PLAYERS_FILE, "DATA") or "", false, true) or {}

local function SettingsKey(ply)
	return ply:IsBot() and ("BOT_" .. ply:Nick()) or ply:SteamID64() or ply:SteamID()
end

local function WritePlayers()
	file.CreateDir("pulse")
	file.Write(PLAYERS_FILE, util.TableToJSON(storedSettings))
end
hook.Add("ShutDown", "HT_SavePlayers", WritePlayers)

-- one-time update: everyone gets the new Default setup
storedSettings._meta = istable(storedSettings._meta) and storedSettings._meta or {}
if (tonumber(storedSettings._meta.version) or 1) < 2 then
	for k, entry in pairs(storedSettings) do
		if k ~= "_meta" and istable(entry) then entry.HT_DefLoadout = nil end
	end
	storedSettings._meta.version = 2
	WritePlayers()
end

-- Applies one setting and returns the cleaned value as text
local function ApplySetting(target, key, raw)
	local s = HT.SettingByKey[key]
	if not s then return end
	if s.type == "bool" then
		target:SetNWBool(key, raw == "1")
		return raw == "1" and "1" or "0"
	elseif key == "HT_DefPill" then
		local pill = HT.ValidPill(raw)
		target:SetNWString(key, pill)
		return pill
	elseif s.type == "string" then
		-- loadouts: store them cleaned up
		local loadout = HT.SerializeLoadout(HT.ParseLoadout(raw).state)
		target:SetNWString(key, loadout)
		HT.RefreshLoadout(target)
		return loadout
	end
	local v = tonumber(raw)
	if not v then return end
	v = math.Clamp(v, s.min, math.max(s.min, s.max()))
	target:SetNWFloat(key, v)
	return tostring(v)
end

function HT.StoreSetting(target, key, value)
	local k = SettingsKey(target)
	storedSettings[k] = storedSettings[k] or {}
	storedSettings[k][key] = value
	timer.Create("HT_SavePlayers", 2, 1, WritePlayers)
end

net.Receive("HT_Set", function(_, ply)
	local target = net.ReadEntity()
	local key = net.ReadString()
	local raw = net.ReadString()
	local restore = net.ReadBool() -- sent from the player's own backup when joining

	if not IsValid(target) or not target:IsPlayer() then return end
	if target ~= ply and not HT.IsManager(ply) then return end

	-- the server's copy wins over the player's backup
	local saved = storedSettings[SettingsKey(target)]
	if restore and saved and saved[key] ~= nil then return end

	local value = ApplySetting(target, key, raw)
	if value ~= nil then HT.StoreSetting(target, key, value) end
end)

hook.Add("PlayerInitialSpawn", "HT_LoadSettings", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) then return end
		for key, value in pairs(storedSettings[SettingsKey(ply)] or {}) do ApplySetting(ply, key, value) end
		HT.RefreshLoadout(ply)
	end)
end)

------------------------------------------------------------------------
-- Abilities with cooldown
------------------------------------------------------------------------

local DECOY_MODEL = "models/props_junk/popcan01a.mdl"

local SendPing -- defined below (noise radar)

-- Finds a free spot along the view direction where the hunter can stand.
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

-- Each action returns cooldown, active duration (nil = failed, no cooldown)
local Actions = {
	chaser = function(ply)
		local duration = HT.Get(ply, "HT_ChaserCfgTime")
		ply:SetNWFloat("HT_ChaserRadius", HT.Get(ply, "HT_ChaserCfgRadius"))
		return duration + CV.chaserCooldown:GetFloat(), duration
	end,

	roar = function(ply, now)
		HT.EmitSlot(ply, "roar", 120, 1, CHAN_VOICE)

		local duration = CV.roarDuration:GetFloat()
		local radiusSqr = CV.roarRadius:GetFloat() ^ 2
		local origin = ply:GetPos()
		local victims = {}
		for _, target in ipairs(player.GetAll()) do
			if HT.IsTarget(ply, target) and origin:DistToSqr(target:GetPos()) <= radiusSqr then
				target:SetNWFloat("HT_SlowFactor", CV.roarSlow:GetFloat())
				target:SetNWFloat("HT_SlowUntil", now + duration)
				HT.Scare(target, 10)
				victims[#victims + 1] = target
			end
		end

		if #victims > 0 then
			net.Start("HT_Roared")
			net.WriteFloat(duration)
			net.Send(victims)
		end
		return CV.roarCooldown:GetFloat(), duration
	end,

	teleport = function(ply)
		local spot = FindTeleportSpot(ply)
		if not spot then
			ply:ChatPrint("[PULSE] No room to teleport there.")
			return
		end
		HT.PlaySlotAt("teleport", ply:GetPos(), 75)
		ply:SetPos(spot)
		ply:SetVelocity(-ply:GetVelocity())
		ply:ScreenFade(SCREENFADE.IN, color_black, 0.4, 0)
		HT.PlaySlotAt("teleport", spot, 80)
		return CV.teleportCooldown:GetFloat()
	end,

	-- Victim: blinds hunters you light up while they look at you
	flash = function(ply)
		HT.EmitSlot(ply, "flash", 75)

		local eye, aim = ply:EyePos(), ply:GetAimVector()
		local range = CV.flashRange:GetFloat()
		local victimCone, hunterCone = math.cos(math.rad(15)), math.cos(math.rad(60))
		local blinded = {}

		for _, hunter in ipairs(player.GetAll()) do
			if HT.IsHunter(hunter) and hunter:Alive() then
				local hunterEye = hunter:EyePos()
				local dir = hunterEye - eye
				if dir:Length() <= range then
					dir:Normalize()
					local victimLooks = aim:Dot(dir) >= victimCone
					local hunterLooks = hunter:GetAimVector():Dot(-dir) >= hunterCone
					if victimLooks and hunterLooks then
						local tr = util.TraceLine({ start = eye, endpos = hunterEye, filter = { ply, hunter }, mask = MASK_VISIBLE })
						if not tr.Hit then blinded[#blinded + 1] = hunter end
					end
				end
			end
		end

		if #blinded > 0 then
			net.Start("HT_Blind")
			net.WriteFloat(CV.flashTime:GetFloat())
			net.Send(blinded)
			ply:ChatPrint("[PULSE] Hunter blinded!")
		else
			ply:ChatPrint("[PULSE] Missed. Light the hunter up while he is looking at you.")
		end
		return CV.flashCooldown:GetFloat()
	end,

	-- Victim: hidden from noise radar, footprints and heartbeat
	silent = function()
		local duration = CV.silentTime:GetFloat()
		return duration + CV.silentCooldown:GetFloat(), duration
	end,

	-- Victim: throw a can, fake ping where it lands
	decoy = function(ply)
		local ent = ents.Create("prop_physics")
		if not IsValid(ent) then return end
		ent:SetModel(DECOY_MODEL)
		ent:SetPos(ply:EyePos() + ply:GetAimVector() * 16)
		ent:SetAngles(ply:EyeAngles())
		ent:SetOwner(ply)
		ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		ent:Spawn()

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then phys:SetVelocity(ply:GetAimVector() * 900 + ply:GetVelocity()) end

		ent:AddCallback("PhysicsCollide", function(e, data)
			if e.HT_Pinged or data.Speed < 80 then return end
			e.HT_Pinged = true
			HT.EmitSlot(e, "decoy_land", 90)
			SendPing(data.HitPos + Vector(0, 0, 40), math.random(1, 2))
		end)
		SafeRemoveEntityDelayed(ent, 8)
		return CV.decoyCooldown:GetFloat()
	end,

	-- Watch the nearest victim; the body stays frozen (see SetupMove)
	stalk = function(ply)
		local victim = NearestVictim(ply)
		if not victim then ply:ChatPrint("[PULSE] No victim to stalk.") return end
		ply:SetNWEntity("HT_StalkTarget", victim)
		local duration = CV.stalkTime:GetFloat()
		return duration + CV.stalkCooldown:GetFloat(), duration
	end,

	-- Appear right behind the nearest victim
	behind = function(ply)
		local victim = NearestVictim(ply, CV.behindRange:GetFloat())
		if not victim then ply:ChatPrint("[PULSE] No victim in range.") return end

		local fwd = victim:GetAimVector() -- where the victim looks; we stand behind them
		fwd.z = 0
		fwd:Normalize()
		local mins, maxs = ply:GetHull()
		local spot
		for _, d in ipairs({ 40, 55, 70, 32 }) do
			local pos = victim:GetPos() - fwd * d
			local free = util.TraceHull({ start = pos + Vector(0, 0, 2), endpos = pos + Vector(0, 0, 2),
				mins = mins, maxs = maxs, filter = { ply, victim }, mask = MASK_PLAYERSOLID })
			local sight = util.TraceLine({ start = victim:EyePos(), endpos = pos + Vector(0, 0, 50),
				filter = { ply, victim }, mask = MASK_SOLID_BRUSHONLY })
			if not free.Hit and not sight.Hit then spot = pos break end
		end
		if not spot then ply:ChatPrint("[PULSE] No room behind the victim.") return end

		ply.HT_BehindReturn = { pos = ply:GetPos(), ang = ply:EyeAngles() }
		ply.HT_BehindVictim = victim
		ply.HT_BehindBreath = 0
		ply.HT_BehindSeen = nil
		ply:SetNWEntity("HT_BehindTarget", victim)
		ply:SetPos(spot)
		ply:SetVelocity(-ply:GetVelocity())
		HT.FaceTarget(ply, victim)

		local duration = CV.behindTime:GetFloat()
		net.Start("HT_ForceHeart")
		net.WriteFloat(duration)
		net.Send(victim)
		return duration + CV.behindCooldown:GetFloat(), duration
	end,

	-- Every victim nearby sees the hunter's face right in front of them
	jump = function(ply)
		local victims = {}
		local radiusSqr = CV.jumpRadius:GetFloat() ^ 2
		for _, target in ipairs(player.GetAll()) do
			if HT.IsTarget(ply, target) and ply:GetPos():DistToSqr(target:GetPos()) <= radiusSqr then
				victims[#victims + 1] = target
				HT.Scare(target, 25)
			end
		end
		if #victims == 0 then ply:ChatPrint("[PULSE] No victim close enough.") return end

		net.Start("HT_Jumpscare")
		net.WriteString(HT.VisualModel(ply))
		net.WriteFloat(CV.jumpTime:GetFloat())
		net.Send(victims)
		ply:ChatPrint("[PULSE] Scared " .. #victims .. (#victims == 1 and " victim." or " victims."))
		return CV.jumpCooldown:GetFloat()
	end,
}

-- Hunter-only: Blackout, Trap, Mark, Mimic, Door Slam
local DOOR_CLASSES = { prop_door_rotating = true, func_door = true, func_door_rotating = true }
local LIGHT_CLASSES = { light = true, light_spot = true, light_dynamic = true }

-- Ends the victim disguise and brings back the hunter's look
function HT.EndMimic(ply)
	if not ply.HT_MimicOld then return end
	local old = ply.HT_MimicOld
	ply.HT_MimicOld = nil
	ply:SetNWFloat("HT_Active_mimic", 0)
	if IsValid(ply) then
		ply:SetModel(old.model)
		ply:SetPlayerColor(old.color)
		ply:DrawWorldModel(true)
	end
end

local traps = {}

function HT.RemoveTraps(ply)
	for _, t in ipairs(traps[ply] or {}) do
		if IsValid(t) then t:Remove() end
	end
	traps[ply] = nil
end

Actions.blackout = function(ply, now)
	local duration = CV.blackoutTime:GetFloat()
	local radius = CV.blackoutRadius:GetFloat()
	local origin = ply:GetPos()
	local victims = {}
	for _, target in ipairs(player.GetAll()) do
		if HT.IsTarget(ply, target) and origin:DistToSqr(target:GetPos()) <= radius ^ 2 then
			victims[#victims + 1] = target
			target:SetNWFloat("HT_BlackoutUntil", now + duration)
			if target:FlashlightIsOn() then target:Flashlight(false) end
			HT.Scare(target, 5)
		end
	end
	if #victims > 0 then
		net.Start("HT_Blackout")
		net.WriteFloat(duration)
		net.Send(victims)
	end

	-- experimental: map lights that the mapper made switchable
	if CV.blackoutMapLights:GetBool() then
		for _, ent in ipairs(ents.FindInSphere(origin, radius)) do
			if LIGHT_CLASSES[ent:GetClass()] and ent:GetName() ~= "" then
				ent:Fire("TurnOff")
				timer.Simple(duration, function() if IsValid(ent) then ent:Fire("TurnOn") end end)
			end
		end
	end
	HT.PlaySlotAt("blackout", ply:GetPos(), 90)
	return CV.blackoutCooldown:GetFloat(), duration
end

Actions.trap = function(ply)
	traps[ply] = traps[ply] or {}
	for i = #traps[ply], 1, -1 do
		if not IsValid(traps[ply][i]) then table.remove(traps[ply], i) end
	end
	if #traps[ply] >= CV.trapMax:GetInt() then
		ply:ChatPrint("[PULSE] You already placed " .. #traps[ply] .. " traps.")
		return
	end

	local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 150, filter = ply, mask = MASK_SOLID_BRUSHONLY })
	local ground = util.TraceLine({ start = tr.HitPos + Vector(0, 0, 10), endpos = tr.HitPos - Vector(0, 0, 100), filter = ply, mask = MASK_SOLID_BRUSHONLY })
	if not ground.Hit or ground.HitNormal.z < 0.7 then ply:ChatPrint("[PULSE] Place the trap on the floor.") return end

	local trap = ents.Create("pulse_trap")
	if not IsValid(trap) then return end
	trap:SetPos(ground.HitPos + Vector(0, 0, 1))
	trap:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	trap:SetOwner(ply)
	trap:Spawn()
	table.insert(traps[ply], trap)
	HT.PlaySlotAt("trap_place", trap:GetPos(), 70)
	return CV.trapCooldown:GetFloat()
end

Actions.mark = function(ply, now)
	local eye, aim = ply:EyePos(), ply:GetAimVector()
	local best, bestDot = nil, math.cos(math.rad(10))
	for _, target in ipairs(player.GetAll()) do
		if HT.IsTarget(ply, target) then
			local dir = target:WorldSpaceCenter() - eye
			if dir:LengthSqr() < 5000 ^ 2 then
				dir:Normalize()
				local dot = aim:Dot(dir)
				if dot > bestDot then
					local tr = util.TraceLine({ start = eye, endpos = target:WorldSpaceCenter(), filter = { ply, target }, mask = MASK_VISIBLE })
					if not tr.Hit then best, bestDot = target, dot end
				end
			end
		end
	end
	if not best then ply:ChatPrint("[PULSE] Aim at a victim you can see.") return end
	best:SetNWFloat("HT_RevealUntil", now + CV.markTime:GetFloat())
	ply:ChatPrint("[PULSE] Marked " .. best:Nick() .. ".")
	HT.SendSlot("mark", best)
	return CV.markCooldown:GetFloat(), CV.markTime:GetFloat()
end

Actions.mimic = function(ply)
	if ply.HT_Pill then ply:ChatPrint("[PULSE] Mimic doesn't work while you are a character from the Pill Pack.") return end
	local victims = {}
	for _, target in ipairs(player.GetAll()) do
		if HT.IsTarget(ply, target) then victims[#victims + 1] = target end
	end
	if #victims == 0 then ply:ChatPrint("[PULSE] No victim to copy.") return end
	local copy = victims[math.random(#victims)]

	if not ply.HT_MimicOld then
		ply.HT_MimicOld = { model = ply:GetModel(), color = ply:GetPlayerColor() }
	end
	ply:SetModel(copy:GetModel())
	ply:SetPlayerColor(copy:GetPlayerColor())
	ply:DrawWorldModel(false)
	ply:ChatPrint("[PULSE] You look like " .. copy:Nick() .. ". Attacking ends the disguise.")
	HT.EmitSlot(ply, "mimic", 70)
	local duration = CV.mimicTime:GetFloat()
	return duration + CV.mimicCooldown:GetFloat(), duration
end

Actions.doorslam = function(ply)
	local count = 0
	local lock = CV.doorLockTime:GetFloat()
	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), CV.doorRadius:GetFloat())) do
		if DOOR_CLASSES[ent:GetClass()] then
			count = count + 1
			ent:Fire("Close")
			ent:Fire("Lock")
			timer.Simple(lock, function() if IsValid(ent) then ent:Fire("Unlock") end end)
			HT.PlaySlotAt("doorslam", ent:WorldSpaceCenter(), 85)
		end
	end
	if count == 0 then ply:ChatPrint("[PULSE] No doors nearby. Door Slam depends on the map.") return end
	for _, target in ipairs(player.GetAll()) do
		if HT.IsTarget(ply, target) and target:GetPos():DistToSqr(ply:GetPos()) < CV.doorRadius:GetFloat() ^ 2 then
			HT.Scare(target, 5)
		end
	end
	return CV.doorCooldown:GetFloat(), lock
end

-- Mimic ends when the hunter attacks, gets hurt or the time is up
hook.Add("KeyPress", "HT_MimicAttack", function(ply, key)
	if ply.HT_MimicOld and (key == IN_ATTACK or key == IN_ATTACK2) then HT.EndMimic(ply) end
end)
hook.Add("EntityTakeDamage", "HT_MimicHurt", function(ent)
	if IsValid(ent) and ent:IsPlayer() and ent.HT_MimicOld then HT.EndMimic(ent) end
end)
timer.Create("HT_MimicTick", 0.5, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply.HT_MimicOld and (not HT.IsActive(ply, "mimic") or not HT.IsHunter(ply) or not ply:Alive()) then HT.EndMimic(ply) end
	end
end)

-- No flashlight during a blackout
hook.Add("PlayerSwitchFlashlight", "HT_Blackout", function(ply, on)
	if on and ply:GetNWFloat("HT_BlackoutUntil", 0) > CurTime() then return false end
end)

hook.Add("PlayerDisconnected", "HT_Traps", function(ply) HT.RemoveTraps(ply) end)

-- Turn the hunter (and a Pill Pack character) toward the victim
function HT.FaceTarget(ply, target)
	local ang = (target:EyePos() - ply:EyePos()):Angle()
	ang.r = 0
	ply:SetEyeAngles(ang)
	if HT.PillsInstalled() and pk_pills.getMappedEnt then
		local ent = pk_pills.getMappedEnt(ply)
		if IsValid(ent) then ent:SetAngles(Angle(0, ang.y, 0)) end
	end
end

-- Brings the hunter back from "Behind You"
local function ReturnFromBehind(ply)
	local ret = ply.HT_BehindReturn
	ply.HT_BehindVictim = nil
	ply.HT_BehindReturn = nil
	ply.HT_BehindSeen = nil
	ply:SetNWFloat("HT_Active_behind", 0)
	ply:SetNWEntity("HT_BehindTarget", NULL)
	if ret and IsValid(ply) and ply:Alive() then
		ply:SetPos(ret.pos)
		ply:SetEyeAngles(ret.ang)
		ply:ScreenFade(SCREENFADE.IN, color_black, 0.5, 0)
	end
end

-- Behind You sounds: own files in sound/pulse/behindu/behind/ and .../turn/ (see sh_sounds.lua)
local function BehindSound(id, pos, level)
	local len = HT.PlaySlotAt(id, pos, level)
	return (len > 0 and len < 15) and len or 2
end
local TURN_CONE = math.cos(math.rad(55))
local SEEN_TIME = 1 -- the hunter stays visible this long after the victim turned around

-- While behind a victim: breathe, vanish if they turn around, return if they walk away
timer.Create("HT_BehindTick", 0.1, 0, function()
	local now = CurTime()
	for _, ply in ipairs(player.GetAll()) do
		local victim = ply.HT_BehindVictim
		if victim then
			if not HT.IsActive(ply, "behind") or not HT.IsHunter(ply) or not IsValid(victim) or not HT.IsVictim(victim) then
				ReturnFromBehind(ply)
			elseif victim:GetPos():DistToSqr(ply:GetPos()) > 250 ^ 2 then
				ReturnFromBehind(ply) -- walked away: nothing happens
			elseif ply.HT_BehindSeen then
				HT.FaceTarget(ply, victim)
				if now >= ply.HT_BehindSeen then ReturnFromBehind(ply) end
			else
				HT.FaceTarget(ply, victim)
				local dir = ply:EyePos() - victim:EyePos()
				dir:Normalize()
				if victim:GetAimVector():Dot(dir) > TURN_CONE then
					-- seen: stay a moment so the victim really sees the hunter, then vanish
					BehindSound("behind_turn", ply:EyePos(), #HT.OwnSounds("behind_turn") > 0 and 75 or 55)
					HT.Scare(victim, 20)
					ply.HT_BehindSeen = now + SEEN_TIME
					ply:SetNWFloat("HT_Active_behind", now + SEEN_TIME + 0.5)
				elseif now > (ply.HT_BehindBreath or 0) then
					-- next sound after this one ends (short pause in between)
					local len = BehindSound("behind", ply:EyePos(), 65)
					ply.HT_BehindBreath = now + math.max(2.5, len + math.Rand(0.5, 1.5))
				end
			end
		end
	end
end)

-- Frozen hunters (stalk, behind you) can't hurt anyone
hook.Add("EntityTakeDamage", "HT_FrozenHunter", function(_, dmg)
	local attacker = HT.OwnerPlayer(dmg:GetAttacker())
	if HT.IsHunter(attacker) and (HT.IsActive(attacker, "stalk") or HT.IsActive(attacker, "behind")) then return true end
end)

net.Receive("HT_Ability", function(_, ply)
	local id = net.ReadString()
	local def = HT.AbilityByID[id]
	if not def then return end

	if def.hunter then
		if not HT.HunterCanAct(ply) or not HT.CanTrigger(ply, id) then return end

		-- toggles: the client sends the state it wants, so a lost or doubled press can't flip it the wrong way
		if def.kind == "toggle" then
			ply:SetNWBool("HT_T_" .. id, net.ReadBool())
			return
		end
		if HT.IsActive(ply, "stalk") or HT.IsActive(ply, "behind") then return end
	else
		if not HT.IsVictim(ply) or not def.allow:GetBool() or def.kind ~= "active" then return end
	end

	local action = Actions[id]
	if not action then return end -- scary sounds use HT_SoundPlay

	local now = CurTime()
	if ply:GetNWFloat("HT_Ready_" .. id, 0) > now then return end

	local cooldown, active = action(ply, now)
	if not cooldown then return end
	-- scared victims need longer to recover
	if not def.hunter then cooldown = cooldown * (1 + HT.Fear(ply)) end
	ply:SetNWFloat("HT_Ready_" .. id, now + cooldown)
	ply:SetNWFloat("HT_Active_" .. id, active and now + active or 0)
end)

------------------------------------------------------------------------
-- Senses: noise radar, footprints, heartbeat, hiding bonus
------------------------------------------------------------------------

local function HuntersWith(id)
	local list = {}
	for _, ply in ipairs(player.GetAll()) do
		if HT.IsOn(ply, id) then list[#list + 1] = ply end
	end
	return list
end

local NOISE_STEPS, NOISE_SPRINT, NOISE_JUMP, NOISE_SHOT = 0, 1, 2, 3
local lastNoise = {}

function SendPing(pos, kind)
	local radiusSqr = CV.noiseRadius:GetFloat() ^ 2
	for _, hunter in ipairs(HuntersWith("noise")) do
		if hunter:GetPos():DistToSqr(pos) <= radiusSqr then
			net.Start("HT_Ping")
			net.WriteVector(pos)
			net.WriteUInt(kind, 2)
			net.Send(hunter)
		end
	end
end
HT.SendPing = SendPing

local function MakeNoise(ply, kind)
	if not HT.IsVictim(ply) or HT.IsSilent(ply) then return end
	local now = CurTime()
	-- one ping per victim every few seconds
	if (lastNoise[ply] or 0) > now - CV.noiseInterval:GetFloat() then return end
	lastNoise[ply] = now
	SendPing(ply:GetPos() + Vector(0, 0, 40), kind)
end

hook.Add("KeyPress", "HT_NoiseJump", function(ply, key)
	if key == IN_JUMP and ply:OnGround() then MakeNoise(ply, NOISE_JUMP) end
end)

hook.Add("EntityFireBullets", "HT_NoiseShot", function(ent)
	if IsValid(ent) and ent:IsPlayer() then MakeNoise(ent, NOISE_SHOT) end
end)

local lastPrint = {}

timer.Create("HT_SensesTick", 0.25, 0, function()
	local trackers = HuntersWith("tracks")
	local listeners = HuntersWith("heart")
	local prints = {}

	for _, ply in ipairs(player.GetAll()) do
		if HT.IsVictim(ply) then
			local vel = ply:GetVelocity()
			local silent = HT.IsSilent(ply)

			-- Hiding bonus: crouch still for a while
			local hidden = false
			if CV.allowHide:GetBool() and ply:Crouching() and ply:OnGround() and vel:Length2DSqr() < 25 then
				ply.HT_StillSince = ply.HT_StillSince or CurTime()
				hidden = CurTime() - ply.HT_StillSince >= CV.hideTime:GetFloat()
			else
				ply.HT_StillSince = nil
			end
			if ply:GetNWBool("HT_Hidden", false) ~= hidden then
				ply:SetNWBool("HT_Hidden", hidden)
				if hidden then HT.SendSlot("hidden", ply) end
			end

			-- Sprinting is loud, walking and sneaking are not (insane victims are loud when walking too)
			local insane = HT.IsInsane(ply)
			if ply:OnGround() and ply:KeyDown(IN_SPEED) and not ply:Crouching() and vel:Length2DSqr() > 180 ^ 2 then
				MakeNoise(ply, NOISE_SPRINT)
			elseif insane and ply:OnGround() and not ply:Crouching() and vel:Length2DSqr() > 60 ^ 2 then
				MakeNoise(ply, NOISE_STEPS)
			end

			-- Insane victims light up for the hunter now and then
			local now = CurTime()
			if insane then
				ply.HT_NextReveal = ply.HT_NextReveal or now + 5
				if now >= ply.HT_NextReveal then
					ply.HT_NextReveal = now + math.random(18, 30)
					ply:SetNWFloat("HT_RevealUntil", now + 2.5)
				end
			else
				ply.HT_NextReveal = nil
			end

			-- Sanity: seeing a hunter lowers it, staying with others slowly raises it
			if CV.sanityEnabled:GetBool() then
				local eye, aim = ply:EyePos(), ply:GetAimVector()
				for _, hunter in ipairs(player.GetAll()) do
					if HT.IsHunter(hunter) and hunter:Alive() and HT.Phase() ~= "prep" then
						local dir = hunter:EyePos() - eye
						if dir:LengthSqr() < 1500 ^ 2 then
							dir:Normalize()
							if aim:Dot(dir) > 0.75 then
								local tr = util.TraceLine({ start = eye, endpos = hunter:EyePos(), filter = { ply, hunter }, mask = MASK_VISIBLE })
								if not tr.Hit then ChangeSanity(ply, -CV.sanitySee:GetFloat() * 0.25) break end
							end
						end
					end
				end

				local together = false
				for _, other in ipairs(player.GetAll()) do
					if other ~= ply and HT.IsVictim(other) and other:GetPos():DistToSqr(ply:GetPos()) < 300 ^ 2 then
						together = true
						break
					end
				end
				if together then
					ply.HT_TogetherSince = ply.HT_TogetherSince or now
					if now - ply.HT_TogetherSince >= CV.sanityGroupTime:GetFloat() then
						ChangeSanity(ply, CV.sanityRegen:GetFloat() * 0.25)
					end
				else
					ply.HT_TogetherSince = nil
				end
			end

			-- A footprint every ~36 units, alternating left and right
			if #trackers > 0 and ply:OnGround() and not silent then
				local pos = ply:GetPos()
				local last = lastPrint[ply]
				if not last or last.pos:DistToSqr(pos) > 36 ^ 2 then
					local left = not (last and last.left)
					lastPrint[ply] = { pos = pos, left = left }
					prints[#prints + 1] = { ply = ply, pos = pos, yaw = vel:Angle().y, left = left, long = insane }
				end
			end
		end
	end

	if #prints > 0 then
		local radiusSqr = CV.tracksRadius:GetFloat() ^ 2
		for _, hunter in ipairs(trackers) do
			local origin, mine = hunter:GetPos(), {}
			for _, p in ipairs(prints) do
				if HT.IsTarget(hunter, p.ply) and origin:DistToSqr(p.pos) <= radiusSqr then
					mine[#mine + 1] = p
				end
			end
			if #mine > 0 then
				local count = math.min(#mine, 255)
				net.Start("HT_Tracks")
				net.WriteUInt(count, 8)
				for i = 1, count do
					net.WriteVector(mine[i].pos)
					net.WriteFloat(mine[i].yaw)
					net.WriteBool(mine[i].left)
					net.WriteBool(mine[i].long)
				end
				net.Send(hunter)
			end
		end
	end

	-- Heartbeat sensor: only the distance to the nearest victim, no direction
	for _, hunter in ipairs(listeners) do
		local origin, nearest = hunter:GetPos(), -1
		for _, target in ipairs(player.GetAll()) do
			if HT.IsTarget(hunter, target) and not HT.IsSilent(target) then
				local d = origin:Distance(target:GetPos())
				if nearest < 0 or d < nearest then nearest = d end
			end
		end
		net.Start("HT_Heart")
		net.WriteFloat(nearest)
		net.Send(hunter)
	end

	-- Victim heartbeat: distance to the nearest hunter
	if CV.victimHeart:GetBool() then
		local hunters = {}
		for _, ply in ipairs(player.GetAll()) do
			if HT.IsHunter(ply) and ply:Alive() then hunters[#hunters + 1] = ply end
		end
		if #hunters > 0 then
			for _, victim in ipairs(player.GetAll()) do
				if HT.IsVictim(victim) then
					local nearest = -1
					for _, hunter in ipairs(hunters) do
						local d = hunter:GetPos():Distance(victim:GetPos())
						if nearest < 0 or d < nearest then nearest = d end
					end
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

-- Victims behind walls are normally not sent to the client (PVS).
-- For hunters we add their positions while radar or chaser pulse is on.
hook.Add("SetupPlayerVisibility", "HT_PVS", function(ply)
	if not HT.IsHunter(ply) then return end

	local stalked = HT.IsActive(ply, "stalk") and ply:GetNWEntity("HT_StalkTarget")
	if IsValid(stalked) then AddOriginToPVS(stalked:GetPos()) end

	for _, target in ipairs(player.GetAll()) do
		if HT.IsRevealed(target) and HT.IsTarget(ply, target) and not HT.IsHidden(target) then AddOriginToPVS(target:GetPos()) end
	end

	local radar = HT.IsOn(ply, "radar")
	local chaser = HT.IsActive(ply, "chaser")
	if not radar and not chaser then return end

	local origin = ply:GetPos()
	local radiusSqr = ply:GetNWFloat("HT_ChaserRadius", 0) ^ 2

	for _, target in ipairs(player.GetAll()) do
		if HT.IsTarget(ply, target) and not HT.IsHidden(target) then
			local pos = target:GetPos()
			if radar or origin:DistToSqr(pos) <= radiusSqr then
				AddOriginToPVS(pos)
			end
		end
	end
end)

-- Adrenaline: a victim hit by the hunter is faster for a moment
-- A hit stops the hunter's sprint for a moment
hook.Add("PostEntityTakeDamage", "HT_HunterHurt", function(ent, dmg, took)
	if not took or not IsValid(ent) or dmg:GetDamage() <= 0 then return end
	-- Pill Pack characters take the damage on their own entity
	if not ent:IsPlayer() then
		local owner = HT.OwnerPlayer(ent)
		if not (IsValid(owner) and owner:IsPlayer() and pk_pills and pk_pills.getMappedEnt(owner) == ent) then return end
		ent = owner
	end
	if not HT.IsHunter(ent) then return end
	local slow = CV.hunterHurtSlow:GetFloat()
	if slow > 0 then ent:SetNWFloat("HT_HurtUntil", CurTime() + slow) end
end)

hook.Add("PostEntityTakeDamage", "HT_Adrenaline", function(ent, dmg, took)
	if not took or not IsValid(ent) or not ent:IsPlayer() or not HT.IsVictim(ent) then return end

	-- every hit costs sanity
	ChangeSanity(ent, -dmg:GetDamage() * CV.sanityDamage:GetFloat())

	if not CV.allowAdrenaline:GetBool() then return end
	if not HT.IsHunter(HT.OwnerPlayer(dmg:GetAttacker())) then return end

	local now = CurTime()
	if ent:GetNWFloat("HT_AdrenalineReady", 0) > now then return end

	local duration = CV.adrenalineTime:GetFloat()
	ent:SetNWFloat("HT_BoostFactor", CV.adrenalineSpeed:GetFloat())
	ent:SetNWFloat("HT_BoostUntil", now + duration)
	HT.SendSlot("adrenaline", ent)
	ent:SetNWFloat("HT_AdrenalineReady", now + duration + CV.adrenalineCooldown:GetFloat())
end)

------------------------------------------------------------------------
-- Scary sounds
------------------------------------------------------------------------

local soundList = {}

-- Built-in HL2 sounds + own files from sound/pulse/
local function BuildSoundList()
	soundList = {}
	for _, entry in ipairs(HT.BuiltinSounds) do
		if file.Exists("sound/" .. entry[2], "GAME") then
			soundList[#soundList + 1] = { name = entry[1], path = entry[2] }
		end
	end

	-- own files: sound/pulse/scary/ (and, like before, directly in sound/pulse/)
	local own = HT.SoundFolderFiles("scary")
	table.Add(own, HT.SoundFolderFiles(""))
	for _, path in ipairs(own) do
		resource.AddFile("sound/" .. path) -- friends download the file when joining
		local name = string.gsub(string.StripExtension(string.GetFileFromFilename(path)), "_", " ")
		soundList[#soundList + 1] = { name = "★ " .. name, path = path }
	end
end
BuildSoundList()

local function SendSoundList(ply)
	local count = math.min(#soundList, 255)
	net.Start("HT_SoundList")
	net.WriteUInt(count, 8)
	for i = 1, count do net.WriteString(soundList[i].name) end
	net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "HT_SoundList", function(ply)
	timer.Simple(3, function() if IsValid(ply) then SendSoundList(ply) end end)
end)

-- A spot a bit behind a random victim (not inside a wall)
local function SpotNearRandomVictim(hunter)
	local victims = {}
	for _, ply in ipairs(player.GetAll()) do
		if HT.IsTarget(hunter, ply) then victims[#victims + 1] = ply end
	end
	if #victims == 0 then return end

	local victim = victims[math.random(#victims)]
	local eye = victim:EyePos()
	local back = -victim:GetAimVector()
	back.z = 0
	back:Normalize()
	local tr = util.TraceLine({
		start = eye,
		endpos = eye + back * math.random(120, 250) + VectorRand() * 40,
		filter = victim,
		mask = MASK_SOLID_BRUSHONLY,
	})
	return tr.HitPos + tr.HitNormal * 8
end

net.Receive("HT_SoundPlay", function(_, ply)
	local index = net.ReadUInt(8)
	local mode = net.ReadUInt(3)

	-- index 0 = just send the list again (menu opened)
	if index == 0 then SendSoundList(ply) return end

	if not HT.HunterCanAct(ply) or not HT.HasAbility(ply, "sounds") then return end
	local entry = soundList[index]
	if not entry then return end

	local now = CurTime()
	if ply:GetNWFloat("HT_Ready_sounds", 0) > now then return end

	local level = CV.soundLevel:GetInt()
	local soundPos
	if mode == 1 then
		soundPos = ply:EyePos()
		sound.Play(entry.path, ply:EyePos(), level)
	elseif mode == 2 then
		local pos = SpotNearRandomVictim(ply)
		if not pos then ply:ChatPrint("[PULSE] No victim around.") return end
		soundPos = pos
		sound.Play(entry.path, pos, level)
	elseif mode == 3 then
		local eye = ply:EyePos()
		local tr = util.TraceLine({
			start = eye,
			endpos = eye + ply:GetAimVector() * CV.soundRange:GetFloat(),
			filter = ply,
			mask = MASK_SOLID_BRUSHONLY,
		})
		soundPos = tr.HitPos + tr.HitNormal * 8
		sound.Play(entry.path, soundPos, level)
	elseif mode == 4 then
		if not CV.soundAllowGlobal:GetBool() then return end
		net.Start("HT_SoundGlobal")
		net.WriteString(entry.path)
		net.Broadcast()
		for _, v in ipairs(player.GetAll()) do HT.Scare(v, 5) end
	else
		return
	end

	if soundPos then
		for _, v in ipairs(player.GetAll()) do
			if v:GetPos():DistToSqr(soundPos) < 800 ^ 2 then HT.Scare(v, 5) end
		end
	end

	ply:SetNWFloat("HT_Ready_sounds", now + CV.soundCooldown:GetFloat())
end)

------------------------------------------------------------------------
-- Stamina (victims, during rounds). Low sanity drains it faster.
------------------------------------------------------------------------

timer.Create("HT_Stamina", 0.1, 0, function()
	local enabled = CV.staminaEnabled:GetBool() and HT.InRound()
	for _, ply in ipairs(player.GetAll()) do
		local exhausted = ply:GetNWBool("HT_Exhausted", false)
		local st = ply:GetNWFloat("HT_Stamina", 100)

		if not enabled or not HT.IsVictim(ply) then
			if exhausted then ply:SetNWBool("HT_Exhausted", false) end
			if st ~= 100 then ply:SetNWFloat("HT_Stamina", 100) end
		else
			local fast = ply:GetVelocity():Length2D() > ply:GetWalkSpeed() + 20
			local new
			if ply:KeyDown(IN_SPEED) and ply:OnGround() and fast and not exhausted then
				new = st - 100 / CV.staminaSprint:GetFloat() * 0.1
			else
				new = st + 100 / CV.staminaRegen:GetFloat() * 0.1
			end
			new = math.Clamp(new, 0, 100)

			if new <= 0 and not exhausted then
				ply:SetNWBool("HT_Exhausted", true)
				HT.SendSlot("exhausted", ply)
			elseif exhausted and new >= 30 then
				ply:SetNWBool("HT_Exhausted", false)
			end
			if math.abs(new - st) > 0.4 or new == 0 or new == 100 then ply:SetNWFloat("HT_Stamina", new) end
		end
	end
end)
