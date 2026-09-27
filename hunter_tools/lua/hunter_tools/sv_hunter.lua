-- Hunter Tools: server side of all abilities
-- The server decides who is a hunter. Only hunters get victim positions sent to them.

local HT = HunterTools
local CV = HT.CV

for _, name in ipairs({
	"HT_Set", "HT_Ability", "HT_AdminSetHunter", "HT_AdminSetCVar",
	"HT_Roared", "HT_Ping", "HT_Tracks", "HT_Heart", "HT_Blind",
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
end

function HT.SetHunter(ply, state, quiet)
	if HT.IsHunter(ply) == state then return end
	ply:SetNWBool("HT_Hunter", state)
	HT.ResetAbilityState(ply)
	HT.RefreshLoadout(ply)
	if not quiet then
		PrintMessage(HUD_PRINTTALK, "[Hunter] " .. ply:Nick() .. (state and " is now a hunter." or " is no longer a hunter."))
	end
end

hook.Add("PlayerInitialSpawn", "HT_Join", function(ply)
	timer.Simple(5, function()
		if not IsValid(ply) then return end
		HT.RefreshLoadout(ply)
		ply:ChatPrint("[Hunter] Hunter Tools loaded. Press F5 to open the menu.")
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

net.Receive("HT_AdminSetCVar", function(_, ply)
	local name = net.ReadString()
	local value = net.ReadFloat()
	if not HT.IsManager(ply) then return end
	local cv = editable[name]
	if not cv then return end
	value = math.Clamp(value, cv:GetMin() or value, cv:GetMax() or value)
	RunConsoleCommand(name, tostring(value))
end)

-- Personal hunter settings: for yourself, or as admin for someone else
net.Receive("HT_Set", function(_, ply)
	local target = net.ReadEntity()
	local key = net.ReadString()
	local raw = net.ReadString()

	if not IsValid(target) or not target:IsPlayer() then return end
	if target ~= ply and not HT.IsManager(ply) then return end

	local s = HT.SettingByKey[key]
	if not s then return end

	if s.type == "bool" then
		target:SetNWBool(key, raw == "1")
	elseif s.type == "string" then
		-- only loadouts are strings; store them cleaned up
		target:SetNWString(key, HT.SerializeLoadout(HT.ParseLoadout(raw).state))
		HT.RefreshLoadout(target)
	else
		local v = tonumber(raw)
		if not v then return end
		target:SetNWFloat(key, math.Clamp(v, s.min, math.max(s.min, s.max())))
	end
end)

------------------------------------------------------------------------
-- Abilities with cooldown
------------------------------------------------------------------------

local ROAR_SOUND = "npc/fast_zombie/fz_scream1.wav"
local TELEPORT_SOUND = "npc/stalker/go_alert2a.wav"
local FLASH_SOUND = "items/flashlight1.wav"
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
		ply:EmitSound(ROAR_SOUND, 120, 80, 1, CHAN_VOICE)

		local duration = CV.roarDuration:GetFloat()
		local radiusSqr = CV.roarRadius:GetFloat() ^ 2
		local origin = ply:GetPos()
		local victims = {}
		for _, target in ipairs(player.GetAll()) do
			if HT.IsTarget(ply, target) and origin:DistToSqr(target:GetPos()) <= radiusSqr then
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
		return CV.roarCooldown:GetFloat(), duration
	end,

	teleport = function(ply)
		local spot = FindTeleportSpot(ply)
		if not spot then
			ply:ChatPrint("[Hunter] No room to teleport there.")
			return
		end
		ply:EmitSound(TELEPORT_SOUND, 75, 70)
		ply:SetPos(spot)
		ply:SetVelocity(-ply:GetVelocity())
		ply:ScreenFade(SCREENFADE.IN, color_black, 0.4, 0)
		sound.Play(TELEPORT_SOUND, spot, 80, 60)
		return CV.teleportCooldown:GetFloat()
	end,

	-- Victim: blinds hunters you light up while they look at you
	flash = function(ply)
		ply:EmitSound(FLASH_SOUND, 75, 90)

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
			ply:ChatPrint("[Hunter] Hunter blinded!")
		else
			ply:ChatPrint("[Hunter] Missed. Light the hunter up while he is looking at you.")
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
			e:EmitSound("physics/metal/soda_can_impact_hard" .. math.random(1, 3) .. ".wav", 90)
			SendPing(data.HitPos + Vector(0, 0, 40), math.random(1, 2))
		end)
		SafeRemoveEntityDelayed(ent, 8)
		return CV.decoyCooldown:GetFloat()
	end,
}

net.Receive("HT_Ability", function(_, ply)
	local id = net.ReadString()
	local def = HT.AbilityByID[id]
	if not def then return end

	if def.hunter then
		if not HT.HunterCanAct(ply) then return end
		local st = HT.Loadout(ply).state[id]
		if type(st) ~= "number" then return end -- must be on a slot

		if def.kind == "toggle" then
			ply:SetNWBool("HT_T_" .. id, not ply:GetNWBool("HT_T_" .. id, false))
			return
		end
	else
		if not HT.IsVictim(ply) or not def.allow:GetBool() or def.kind ~= "active" then return end
	end

	local action = Actions[id]
	if not action then return end -- scary sounds use HT_SoundPlay

	local now = CurTime()
	if ply:GetNWFloat("HT_Ready_" .. id, 0) > now then return end

	local cooldown, active = action(ply, now)
	if not cooldown then return end
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

local NOISE_SPRINT, NOISE_JUMP, NOISE_SHOT = 1, 2, 3
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

local function MakeNoise(ply, kind)
	if not HT.IsVictim(ply) or HT.IsSilent(ply) then return end
	local now = CurTime()
	if (lastNoise[ply] or 0) > now - 0.6 then return end
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
			if ply:GetNWBool("HT_Hidden", false) ~= hidden then ply:SetNWBool("HT_Hidden", hidden) end

			-- Sprinting is loud, walking and sneaking are not
			if ply:OnGround() and ply:KeyDown(IN_SPEED) and not ply:Crouching() and vel:Length2DSqr() > 180 ^ 2 then
				MakeNoise(ply, NOISE_SPRINT)
			end

			-- A footprint every ~36 units, alternating left and right
			if #trackers > 0 and ply:OnGround() and not silent then
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
hook.Add("PostEntityTakeDamage", "HT_Adrenaline", function(ent, dmg, took)
	if not took or not CV.allowAdrenaline:GetBool() then return end
	if not IsValid(ent) or not ent:IsPlayer() or not HT.IsVictim(ent) then return end
	if not HT.IsHunter(dmg:GetAttacker()) then return end

	local now = CurTime()
	if ent:GetNWFloat("HT_AdrenalineReady", 0) > now then return end

	local duration = CV.adrenalineTime:GetFloat()
	ent:SetNWFloat("HT_BoostFactor", CV.adrenalineSpeed:GetFloat())
	ent:SetNWFloat("HT_BoostUntil", now + duration)
	ent:SetNWFloat("HT_AdrenalineReady", now + duration + CV.adrenalineCooldown:GetFloat())
end)

------------------------------------------------------------------------
-- Scary sounds
------------------------------------------------------------------------

local SOUND_EXT = { wav = true, mp3 = true, ogg = true }
local soundList = {}

-- Built-in HL2 sounds + own files from sound/hunter_tools/
local function BuildSoundList()
	soundList = {}
	for _, entry in ipairs(HT.BuiltinSounds) do
		if file.Exists("sound/" .. entry[2], "GAME") then
			soundList[#soundList + 1] = { name = entry[1], path = entry[2] }
		end
	end

	local files = file.Find("sound/hunter_tools/*", "GAME")
	table.sort(files)
	for _, f in ipairs(files) do
		local ext = string.lower(string.GetExtensionFromFilename(f) or "")
		if SOUND_EXT[ext] then
			local path = "hunter_tools/" .. f
			resource.AddFile("sound/" .. path) -- friends download the file when joining
			local name = string.gsub(string.StripExtension(f), "_", " ")
			soundList[#soundList + 1] = { name = "★ " .. name, path = path }
		end
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
	if mode == 1 then
		sound.Play(entry.path, ply:EyePos(), level)
	elseif mode == 2 then
		local pos = SpotNearRandomVictim(ply)
		if not pos then ply:ChatPrint("[Hunter] No victim around.") return end
		sound.Play(entry.path, pos, level)
	elseif mode == 3 then
		local eye = ply:EyePos()
		local tr = util.TraceLine({
			start = eye,
			endpos = eye + ply:GetAimVector() * CV.soundRange:GetFloat(),
			filter = ply,
			mask = MASK_SOLID_BRUSHONLY,
		})
		sound.Play(entry.path, tr.HitPos + tr.HitNormal * 8, level)
	elseif mode == 4 then
		if not CV.soundAllowGlobal:GetBool() then return end
		net.Start("HT_SoundGlobal")
		net.WriteString(entry.path)
		net.Broadcast()
	else
		return
	end

	ply:SetNWFloat("HT_Ready_sounds", now + CV.soundCooldown:GetFloat())
end)
