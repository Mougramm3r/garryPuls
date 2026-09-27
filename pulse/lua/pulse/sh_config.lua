-- PULSE: shared definitions (server + client)

Pulse = Pulse or {}
local HT = Pulse

local SV_FLAGS = { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }

-- Values for every ability. Which abilities a hunter has is decided by roles (see Game tab).
HT.CV = {
	aimMaxStrength     = CreateConVar("pulse_aim_max_strength", "0.8", SV_FLAGS, "Aim assist: max strength (0-1)", 0, 1),
	aimMaxFov          = CreateConVar("pulse_aim_max_fov", "20", SV_FLAGS, "Aim assist: max angle in degrees", 1, 45),
	chaserMaxRadius    = CreateConVar("pulse_chaser_max_radius", "3000", SV_FLAGS, "Chaser pulse: max radius in units", 100, 20000),
	chaserMaxTime      = CreateConVar("pulse_chaser_max_duration", "10", SV_FLAGS, "Chaser pulse: max duration in seconds", 1, 60),
	chaserCooldown     = CreateConVar("pulse_chaser_cooldown", "15", SV_FLAGS, "Chaser pulse: cooldown in seconds", 0, 600),

	roarRadius         = CreateConVar("pulse_roar_radius", "600", SV_FLAGS, "Roar: radius in units", 100, 3000),
	roarSlow           = CreateConVar("pulse_roar_slow", "0.5", SV_FLAGS, "Roar: victim speed (0.5 = half speed)", 0.1, 1),
	roarDuration       = CreateConVar("pulse_roar_duration", "3", SV_FLAGS, "Roar: slow duration in seconds", 0.5, 10),
	roarCooldown       = CreateConVar("pulse_roar_cooldown", "30", SV_FLAGS, "Roar: cooldown in seconds", 0, 600),

	noiseRadius        = CreateConVar("pulse_noise_radius", "2500", SV_FLAGS, "Noise radar: range in units", 200, 20000),
	tracksRadius       = CreateConVar("pulse_tracks_radius", "3000", SV_FLAGS, "Footprints: range in units", 200, 20000),
	tracksTime         = CreateConVar("pulse_tracks_time", "8", SV_FLAGS, "Footprints: visible for seconds", 1, 30),
	heartRange         = CreateConVar("pulse_heart_range", "1500", SV_FLAGS, "Heartbeat sensor: audible from this distance", 200, 5000),

	teleportRange      = CreateConVar("pulse_teleport_range", "800", SV_FLAGS, "Teleport: max range in units", 100, 5000),
	teleportCooldown   = CreateConVar("pulse_teleport_cooldown", "45", SV_FLAGS, "Teleport: cooldown in seconds", 0, 600),

	soundCooldown      = CreateConVar("pulse_sound_cooldown", "10", SV_FLAGS, "Scary sounds: cooldown in seconds", 0, 300),
	soundLevel         = CreateConVar("pulse_sound_level", "85", SV_FLAGS, "Scary sounds: volume / reach (60 quiet - 140 very far)", 60, 140),
	soundRange         = CreateConVar("pulse_sound_range", "2000", SV_FLAGS, "Scary sounds: max distance for 'where I look'", 200, 10000),
	soundAllowGlobal   = CreateConVar("pulse_sound_allow_global", "1", SV_FLAGS, "Scary sounds: allow 'everywhere' mode", 0, 1),

	victimHeart        = CreateConVar("pulse_victim_heart", "0", SV_FLAGS, "Victims hear a heartbeat when a hunter is near", 0, 1),
	victimHeartRange   = CreateConVar("pulse_victim_heart_range", "1000", SV_FLAGS, "Victim heartbeat: starts at this distance", 200, 5000),

	allowAdrenaline    = CreateConVar("pulse_allow_adrenaline", "1", SV_FLAGS, "Victims: adrenaline after being hit", 0, 1),
	adrenalineSpeed    = CreateConVar("pulse_adrenaline_speed", "1.5", SV_FLAGS, "Adrenaline: speed multiplier", 1, 3),
	adrenalineTime     = CreateConVar("pulse_adrenaline_time", "3", SV_FLAGS, "Adrenaline: duration in seconds", 0.5, 10),
	adrenalineCooldown = CreateConVar("pulse_adrenaline_cooldown", "20", SV_FLAGS, "Adrenaline: cooldown in seconds", 0, 300),

	allowFlash         = CreateConVar("pulse_allow_flash", "1", SV_FLAGS, "Victims: flashlight blind", 0, 1),
	flashRange         = CreateConVar("pulse_flash_range", "600", SV_FLAGS, "Flashlight blind: range in units", 100, 3000),
	flashTime          = CreateConVar("pulse_flash_time", "2.5", SV_FLAGS, "Flashlight blind: blind duration in seconds", 0.5, 10),
	flashCooldown      = CreateConVar("pulse_flash_cooldown", "40", SV_FLAGS, "Flashlight blind: cooldown in seconds", 0, 600),

	allowSilent        = CreateConVar("pulse_allow_silent", "1", SV_FLAGS, "Victims: stay silent", 0, 1),
	silentTime         = CreateConVar("pulse_silent_time", "6", SV_FLAGS, "Stay silent: duration in seconds", 1, 30),
	silentCooldown     = CreateConVar("pulse_silent_cooldown", "45", SV_FLAGS, "Stay silent: cooldown in seconds", 0, 600),

	allowDecoy         = CreateConVar("pulse_allow_decoy", "1", SV_FLAGS, "Victims: decoy", 0, 1),
	decoyCooldown      = CreateConVar("pulse_decoy_cooldown", "25", SV_FLAGS, "Decoy: cooldown in seconds", 0, 600),

	allowHide          = CreateConVar("pulse_allow_hide", "1", SV_FLAGS, "Victims: hiding bonus (crouch still)", 0, 1),
	hideTime           = CreateConVar("pulse_hide_time", "5", SV_FLAGS, "Hiding bonus: crouch still for seconds", 1, 30),

	stalkTime          = CreateConVar("pulse_stalk_time", "6", SV_FLAGS, "Stalk: watch the nearest victim for seconds", 1, 30),
	stalkCooldown      = CreateConVar("pulse_stalk_cooldown", "40", SV_FLAGS, "Stalk: cooldown in seconds", 0, 600),

	behindRange        = CreateConVar("pulse_behind_range", "3000", SV_FLAGS, "Behind You: max distance to the victim", 200, 20000),
	behindTime         = CreateConVar("pulse_behind_time", "10", SV_FLAGS, "Behind You: max seconds behind the victim", 2, 30),
	behindCooldown     = CreateConVar("pulse_behind_cooldown", "60", SV_FLAGS, "Behind You: cooldown in seconds", 0, 600),

	jumpRadius         = CreateConVar("pulse_jump_radius", "700", SV_FLAGS, "Jump scare: radius in units", 100, 5000),
	jumpTime           = CreateConVar("pulse_jump_time", "0.8", SV_FLAGS, "Jump scare: how long the face is shown", 0.2, 3),
	jumpCooldown       = CreateConVar("pulse_jump_cooldown", "60", SV_FLAGS, "Jump scare: cooldown in seconds", 0, 600),

	sanityEnabled      = CreateConVar("pulse_sanity", "1", SV_FLAGS, "Victims have sanity", 0, 1),
	sanityDamage       = CreateConVar("pulse_sanity_damage", "0.5", SV_FLAGS, "Sanity lost per point of damage", 0, 5),
	sanitySee          = CreateConVar("pulse_sanity_see", "3", SV_FLAGS, "Sanity lost per second while seeing a hunter", 0, 30),
	sanityScare        = CreateConVar("pulse_sanity_scare", "1", SV_FLAGS, "Multiplier for sanity lost by scare abilities", 0, 5),
	sanityRegen        = CreateConVar("pulse_sanity_regen", "1.5", SV_FLAGS, "Sanity regained per second near other victims", 0, 20),
	sanityGroupTime    = CreateConVar("pulse_sanity_group_time", "5", SV_FLAGS, "Seconds near another victim before sanity rises", 0, 60),

	staminaEnabled     = CreateConVar("pulse_stamina", "1", SV_FLAGS, "Victims have stamina during rounds", 0, 1),
	staminaSprint      = CreateConVar("pulse_stamina_sprint", "6", SV_FLAGS, "Stamina: seconds of sprint when full", 1, 60),
	staminaRegen       = CreateConVar("pulse_stamina_regen", "8", SV_FLAGS, "Stamina: seconds to refill completely", 1, 60),
}

local CV = HT.CV

------------------------------------------------------------------------
-- Abilities
------------------------------------------------------------------------

-- kind: "active" = use on a slot, "toggle" = on/off on a slot or always on (passive)
HT.HunterAbilities = {
	{ id = "chaser",   name = "Chaser Pulse",     kind = "active", desc = "Victims in range glow like thermal vision for a few seconds." },
	{ id = "roar",     name = "Roar",             kind = "active", desc = "Nearby victims are slowed and their screen shakes." },
	{ id = "teleport", name = "Teleport",         kind = "active", desc = "Teleport to the spot you are looking at." },
	{ id = "sounds",   name = "Scary Sounds",     kind = "active", desc = "Pick a scary sound and play it somewhere." },
	{ id = "aim",      name = "Aim Assist",       kind = "toggle", desc = "Pulls your crosshair toward visible victims." },
	{ id = "radar",    name = "Radar",            kind = "toggle", desc = "See all victims through walls." },
	{ id = "noise",    name = "Noise Radar",      kind = "toggle", desc = "Sprinting, jumping and shooting victims show up as pings." },
	{ id = "tracks",   name = "Footprints",       kind = "toggle", desc = "Victims leave glowing footprints only you can see." },
	{ id = "heart",    name = "Heartbeat Sensor", kind = "toggle", desc = "A heartbeat that gets faster the closer a victim is." },
	{ id = "stalk",    name = "Stalk",            kind = "active", desc = "Watch the nearest victim for a few seconds. Your body stays frozen where it is." },
	{ id = "behind",   name = "Behind You",       kind = "active", desc = "Appear right behind the nearest victim. They hear breathing. If they turn around, you vanish." },
	{ id = "jump",     name = "Jump Scare",       kind = "active", desc = "Every victim nearby sees your face right in front of theirs." },
}

HT.VictimAbilities = {
	{ id = "flash",      name = "Flashlight Blind", kind = "active",  slot = 1, allow = CV.allowFlash,
		desc = "Blinds the hunter if you light him up while he looks at you." },
	{ id = "silent",     name = "Stay Silent",      kind = "active",  slot = 2, allow = CV.allowSilent,
		desc = "Hidden from noise radar, footprints and heartbeat for a few seconds." },
	{ id = "decoy",      name = "Decoy",            kind = "active",  slot = 3, allow = CV.allowDecoy,
		desc = "Throw a can. The hunter gets a fake noise ping where it lands." },
	{ id = "adrenaline", name = "Adrenaline",       kind = "passive", allow = CV.allowAdrenaline,
		desc = "Short speed boost after the hunter hits you." },
	{ id = "hide",       name = "Hiding Bonus",     kind = "passive", allow = CV.allowHide,
		desc = "Crouch still for a while to vanish from radar and chaser pulse." },
}

HT.AbilityByID = {}
for _, a in ipairs(HT.HunterAbilities) do a.hunter = true; HT.AbilityByID[a.id] = a end
for _, a in ipairs(HT.VictimAbilities) do HT.AbilityByID[a.id] = a end

HT.VictimSlots = {}
for _, a in ipairs(HT.VictimAbilities) do
	if a.slot then HT.VictimSlots[a.slot] = a end
end

HT.SLOTS = 4

------------------------------------------------------------------------
-- Loadouts: "teleport=1;sounds=2;stalk=m;tracks=p"  (1-4 = slot, m = menu only, p = passive)
------------------------------------------------------------------------

HT.DEFAULT_LOADOUT = "chaser=1;roar=2;teleport=3;sounds=4"

function HT.ParseLoadout(str)
	local lo = { slots = {}, state = {}, menu = {} }
	for id, v in string.gmatch(str or "", "([%w_]+)=(%w+)") do
		local def = HT.AbilityByID[id]
		if def and def.hunter and not lo.state[id] then
			local n = tonumber(v)
			if n and n >= 1 and n <= HT.SLOTS and not lo.slots[n] then
				lo.slots[n] = id
				lo.state[id] = n
			elseif v == "p" and def.kind == "toggle" then
				lo.state[id] = "p"
			elseif v == "m" then
				lo.state[id] = "m"
			end
		end
	end
	for _, def in ipairs(HT.HunterAbilities) do
		if lo.state[def.id] == "m" then lo.menu[#lo.menu + 1] = def.id end
	end
	return lo
end

-- state map (id -> slot number or "p") to string
function HT.SerializeLoadout(state)
	local parts = {}
	for _, def in ipairs(HT.HunterAbilities) do
		local v = state[def.id]
		if v then parts[#parts + 1] = def.id .. "=" .. tostring(v) end
	end
	return table.concat(parts, ";")
end

local loadoutCache = {}
function HT.Loadout(ply)
	local s = ply:GetNWString("HT_Loadout", "")
	local lo = loadoutCache[s]
	if not lo then
		lo = HT.ParseLoadout(s)
		loadoutCache[s] = lo
	end
	return lo
end

------------------------------------------------------------------------
-- Roles and game settings (synced from the server, saved in data/pulse/)
------------------------------------------------------------------------

HT.DefaultRoles = {
	{ name = "Stalker", loadout = "behind=1;sounds=2;teleport=3;roar=4;stalk=m;tracks=p;heart=p" },
	{ name = "Tracker", loadout = "chaser=1;roar=2;sounds=3;stalk=4;noise=p;tracks=p" },
	{ name = "Brute",   loadout = "roar=1;teleport=2;jump=3;aim=4;heart=p" },
	{ name = "Seer",    loadout = "radar=1;chaser=2;jump=3;sounds=4;stalk=m;heart=p" },
}

HT.GameDefaults = {
	roundTime    = 480,          -- seconds victims must survive
	prepEnabled  = true,
	prepTime     = 30,           -- hiding phase, hunter frozen and blind
	hunterCount  = 1,
	hunterSelect = "random",     -- random | preselected
	roleMode     = "choice",     -- fixed | choice | random
	fixedRole    = "Stalker",
	choiceTime   = 15,
	hunterWeapon = "weapon_crowbar",
}

HT.HunterWeapons = {
	{ "weapon_crowbar", "Crowbar" },
	{ "weapon_stunstick", "Stunstick" },
	{ "weapon_fists", "Fists" },
	{ "", "No weapon" },
}

HT.Roles = HT.Roles or table.Copy(HT.DefaultRoles)
HT.Game = HT.Game or table.Copy(HT.GameDefaults)

function HT.FindRole(name)
	for _, r in ipairs(HT.Roles) do
		if r.name == name then return r end
	end
end

------------------------------------------------------------------------
-- Per-player hunter settings (Hunter > Default tab)
------------------------------------------------------------------------

local function Fixed(v) return function() return v end end
local function Limit(cvar) return function() return cvar:GetFloat() end end

HT.Settings = {
	{ key = "HT_AimOnFire",       type = "bool",   default = false },
	{ key = "HT_AimNPC",          type = "bool",   default = false },
	{ key = "HT_AimStrength",     type = "float",  default = 0.5,  min = 0,   max = Limit(CV.aimMaxStrength) },
	{ key = "HT_AimFov",          type = "float",  default = 12,   min = 1,   max = Limit(CV.aimMaxFov) },
	{ key = "HT_ESPNames",        type = "bool",   default = true },
	{ key = "HT_ChaserCfgRadius", type = "float",  default = 1500, min = 100, max = Limit(CV.chaserMaxRadius) },
	{ key = "HT_ChaserCfgTime",   type = "float",  default = 5,    min = 1,   max = Limit(CV.chaserMaxTime) },
	{ key = "HT_DefLoadout",      type = "string", default = HT.DEFAULT_LOADOUT },
}

HT.SettingByKey = {}
for _, s in ipairs(HT.Settings) do
	s.max = s.max or Fixed(1)
	HT.SettingByKey[s.key] = s
end

function HT.Get(ply, key)
	local s = HT.SettingByKey[key]
	if s.type == "bool" then return ply:GetNWBool(key, s.default) end
	if s.type == "string" then return ply:GetNWString(key, s.default) end
	return math.Clamp(ply:GetNWFloat(key, s.default), s.min, math.max(s.min, s.max()))
end

------------------------------------------------------------------------
-- State helpers
------------------------------------------------------------------------

function HT.Phase() return GetGlobalString("HT_Phase", "lobby") end
function HT.InRound()
	local p = HT.Phase()
	return p == "prep" or p == "hunt"
end
function HT.PhaseEnd() return GetGlobalFloat("HT_PhaseEnd", 0) end

-- Host / superadmin
function HT.IsManager(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() or ply:IsSuperAdmin() then return true end
	return SERVER and ply:IsListenServerHost() or false
end

function HT.IsHunter(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:GetNWBool("HT_Hunter", false)
end

function HT.IsTarget(hunter, ply)
	return IsValid(ply) and ply ~= hunter and ply:Alive()
		and not HT.IsHunter(ply)
		and ply:GetObserverMode() == OBS_MODE_NONE
end

function HT.IsVictim(ply)
	return IsValid(ply) and ply:Alive() and not HT.IsHunter(ply)
		and ply:GetObserverMode() == OBS_MODE_NONE
end

-- Hunters are frozen and blind during the hiding phase
function HT.HunterCanAct(ply)
	return HT.IsHunter(ply) and ply:Alive() and HT.Phase() ~= "prep"
end

function HT.HasAbility(ply, id)
	return HT.IsHunter(ply) and HT.Loadout(ply).state[id] ~= nil
end

-- Toggle abilities: passive = always on, on a slot or in the menu = switched on/off
function HT.IsOn(ply, id)
	if not HT.HunterCanAct(ply) then return false end
	local st = HT.Loadout(ply).state[id]
	if st == "p" then return true end
	if st then return ply:GetNWBool("HT_T_" .. id, false) end
	return false
end

-- Can be triggered (on a slot or menu only)
function HT.CanTrigger(ply, id)
	local st = HT.Loadout(ply).state[id]
	return isnumber(st) or st == "m"
end

function HT.IsActive(ply, id) return ply:GetNWFloat("HT_Active_" .. id, 0) > CurTime() end
function HT.ActiveLeft(ply, id) return math.max(0, ply:GetNWFloat("HT_Active_" .. id, 0) - CurTime()) end
function HT.ReadyIn(ply, id) return math.max(0, ply:GetNWFloat("HT_Ready_" .. id, 0) - CurTime()) end

function HT.IsSilent(ply) return HT.IsActive(ply, "silent") end

-- Sanity (victims): 100 = calm, 0 = insane. Returns 0..1 how scared someone is.
function HT.Sanity(ply)
	if not CV.sanityEnabled:GetBool() then return 100 end
	return ply:GetNWFloat("HT_Sanity", 100)
end
function HT.Fear(ply) return 1 - HT.Sanity(ply) / 100 end
function HT.IsInsane(ply) return CV.sanityEnabled:GetBool() and HT.Sanity(ply) <= 0.5 end
function HT.IsRevealed(ply) return ply:GetNWFloat("HT_RevealUntil", 0) > CurTime() end
function HT.IsHidden(ply) return CV.allowHide:GetBool() and ply:GetNWBool("HT_Hidden", false) end

function HT.FormatTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- Speed: roar slows, adrenaline speeds up (in SetupMove so it is predicted)
hook.Add("SetupMove", "HT_Speed", function(ply, mv)
	-- out of stamina: walking speed only
	if ply:GetNWBool("HT_Exhausted", false) then
		local walk = ply:GetWalkSpeed()
		mv:SetMaxClientSpeed(math.min(mv:GetMaxClientSpeed(), walk))
		mv:SetMaxSpeed(math.min(mv:GetMaxSpeed(), walk))
	end
	-- frozen while stalking or standing behind a victim
	if HT.IsActive(ply, "stalk") or HT.IsActive(ply, "behind") then
		mv:SetMaxClientSpeed(0)
		mv:SetMaxSpeed(0)
		mv:SetVelocity(vector_origin)
		return
	end

	local now, f = CurTime(), 1
	if ply:GetNWFloat("HT_SlowUntil", 0) > now then f = f * ply:GetNWFloat("HT_SlowFactor", 1) end
	if ply:GetNWFloat("HT_BoostUntil", 0) > now then f = f * ply:GetNWFloat("HT_BoostFactor", 1) end
	if f == 1 then return end
	mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * f)
	mv:SetMaxSpeed(mv:GetMaxSpeed() * f)
end)

------------------------------------------------------------------------
-- Scary sounds
------------------------------------------------------------------------

HT.SoundModes = {
	{ id = 1, name = "At my position" },
	{ id = 2, name = "Behind a random victim" },
	{ id = 3, name = "Where I am looking" },
	{ id = 4, name = "Everywhere (in every victim's head)" },
}

-- Half-Life 2 sounds; only the ones installed on the server show up
HT.BuiltinSounds = {
	{ "Children playing / laughing", "ambient/voices/playground_memory.wav" },
	{ "Child scream",                "ambient/creatures/town_child_scream1.wav" },
	{ "Squeaky teddy",               "ambient/creatures/teddy.wav" },
	{ "Sobbing",                     "ambient/creatures/town_scared_sob1.wav" },
	{ "Sobbing 2",                   "ambient/creatures/town_scared_sob2.wav" },
	{ "Scared breathing",            "ambient/creatures/town_scared_breathing1.wav" },
	{ "Woman screaming",             "ambient/voices/f_scream1.wav" },
	{ "Man screaming",               "ambient/voices/m_scream1.wav" },
	{ "Moaning",                     "ambient/creatures/town_moan1.wav" },
	{ "Distant call",                "ambient/creatures/town_zombie_call1.wav" },
	{ "Heavy breathing",             "npc/stalker/breathing3.wav" },
	{ "Strange voices",              "ambient/levels/citadel/strange_talk1.wav" },
	{ "Strange voices 2",            "ambient/levels/citadel/strange_talk3.wav" },
	{ "Zombie murmur",               "npc/zombie/zombie_voice_idle1.wav" },
	{ "Dull thud",                   "ambient/atmosphere/hole_hit1.wav" },
	{ "Rumble",                      "ambient/atmosphere/cave_hit1.wav" },
	{ "Loud knock",                  "physics/wood/wood_crate_impact_hard3.wav" },
}
