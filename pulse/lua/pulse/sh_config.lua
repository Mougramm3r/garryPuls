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
	roarSlow           = CreateConVar("pulse_roar_slow", "0.75", SV_FLAGS, "Roar: victim speed (0.5 = half speed)", 0.1, 1),
	roarDuration       = CreateConVar("pulse_roar_duration", "2", SV_FLAGS, "Roar: slow duration in seconds", 0.5, 10),
	roarCooldown       = CreateConVar("pulse_roar_cooldown", "30", SV_FLAGS, "Roar: cooldown in seconds", 0, 600),

	noiseRadius        = CreateConVar("pulse_noise_radius", "2500", SV_FLAGS, "Noise radar: range in units", 200, 20000),
	noiseInterval      = CreateConVar("pulse_noise_interval", "4", SV_FLAGS, "Noise radar: seconds between two pings of the same victim", 1, 30),
	nvRadius           = CreateConVar("pulse_nv_radius", "650", SV_FLAGS, "Night vision: light radius in units", 150, 3000),
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
	flashTime          = CreateConVar("pulse_flash_time", "5", SV_FLAGS, "Flashlight blind: blind duration in seconds", 0.5, 10),
	flashCooldown      = CreateConVar("pulse_flash_cooldown", "40", SV_FLAGS, "Flashlight blind: cooldown in seconds", 0, 600),

	allowSilent        = CreateConVar("pulse_allow_silent", "1", SV_FLAGS, "Victims: stay silent", 0, 1),
	silentTime         = CreateConVar("pulse_silent_time", "6", SV_FLAGS, "Stay silent: duration in seconds", 1, 30),
	silentCooldown     = CreateConVar("pulse_silent_cooldown", "10", SV_FLAGS, "Stay silent: cooldown in seconds", 0, 600),

	allowDecoy         = CreateConVar("pulse_allow_decoy", "1", SV_FLAGS, "Victims: decoy", 0, 1),
	decoyCooldown      = CreateConVar("pulse_decoy_cooldown", "25", SV_FLAGS, "Decoy: cooldown in seconds", 0, 600),

	allowHide          = CreateConVar("pulse_allow_hide", "1", SV_FLAGS, "Victims: hiding bonus (crouch still)", 0, 1),
	hideTime           = CreateConVar("pulse_hide_time", "5", SV_FLAGS, "Hiding bonus: crouch still for seconds", 1, 30),

	stalkTime          = CreateConVar("pulse_stalk_time", "6", SV_FLAGS, "Stalk: watch the nearest victim for seconds", 1, 30),
	stalkCooldown      = CreateConVar("pulse_stalk_cooldown", "40", SV_FLAGS, "Stalk: cooldown in seconds", 0, 600),

	behindRange        = CreateConVar("pulse_behind_range", "3000", SV_FLAGS, "Behind You: max distance to the victim", 200, 20000),
	behindTime         = CreateConVar("pulse_behind_time", "10", SV_FLAGS, "Behind You: max seconds behind the victim", 2, 30),
	behindCooldown     = CreateConVar("pulse_behind_cooldown", "60", SV_FLAGS, "Behind You: cooldown in seconds", 0, 600),

	hunterHurtSlow     = CreateConVar("pulse_hunter_hurt_slow", "1.5", SV_FLAGS, "Hunter: seconds without sprinting after taking damage (0 = off)", 0, 10),

	jumpRadius         = CreateConVar("pulse_jump_radius", "700", SV_FLAGS, "Jump scare: radius in units", 100, 5000),
	jumpTime           = CreateConVar("pulse_jump_time", "0.8", SV_FLAGS, "Jump scare: how long the face is shown", 0.2, 3),
	jumpCooldown       = CreateConVar("pulse_jump_cooldown", "60", SV_FLAGS, "Jump scare: cooldown in seconds", 0, 600),

	sanityEnabled      = CreateConVar("pulse_sanity", "1", SV_FLAGS, "Victims have sanity", 0, 1),
	sanityDamage       = CreateConVar("pulse_sanity_damage", "0.5", SV_FLAGS, "Sanity lost per point of damage", 0, 5),
	sanitySee          = CreateConVar("pulse_sanity_see", "0.5", SV_FLAGS, "Sanity lost per second while seeing a hunter", 0, 30),
	sanityScare        = CreateConVar("pulse_sanity_scare", "1", SV_FLAGS, "Multiplier for sanity lost by scare abilities", 0, 5),
	sanityRegen        = CreateConVar("pulse_sanity_regen", "1.5", SV_FLAGS, "Sanity regained per second near other victims", 0, 20),
	sanityGroupTime    = CreateConVar("pulse_sanity_group_time", "5", SV_FLAGS, "Seconds near another victim before sanity rises", 0, 60),

	staminaEnabled     = CreateConVar("pulse_stamina", "1", SV_FLAGS, "Victims have stamina during rounds", 0, 1),
	staminaSprint      = CreateConVar("pulse_stamina_sprint", "6", SV_FLAGS, "Stamina: seconds of sprint when full", 1, 60),
	staminaRegen       = CreateConVar("pulse_stamina_regen", "8", SV_FLAGS, "Stamina: seconds to refill completely", 1, 60),

	blackoutRadius     = CreateConVar("pulse_blackout_radius", "800", SV_FLAGS, "Blackout: radius in units", 100, 5000),
	blackoutTime       = CreateConVar("pulse_blackout_time", "8", SV_FLAGS, "Blackout: duration in seconds", 1, 60),
	blackoutCooldown   = CreateConVar("pulse_blackout_cooldown", "60", SV_FLAGS, "Blackout: cooldown in seconds", 0, 600),
	blackoutMapLights  = CreateConVar("pulse_blackout_maplights", "1", SV_FLAGS, "Blackout: also switch off map lights that can be switched (experimental)", 0, 1),

	trapMax            = CreateConVar("pulse_trap_max", "3", SV_FLAGS, "Trap: max traps per hunter", 1, 10),
	trapTime           = CreateConVar("pulse_trap_time", "3", SV_FLAGS, "Trap: victims are held for seconds", 0.5, 15),
	trapCooldown       = CreateConVar("pulse_trap_cooldown", "20", SV_FLAGS, "Trap: cooldown in seconds", 0, 600),

	markTime           = CreateConVar("pulse_mark_time", "10", SV_FLAGS, "Mark: victim stays visible for seconds", 1, 60),
	markCooldown       = CreateConVar("pulse_mark_cooldown", "45", SV_FLAGS, "Mark: cooldown in seconds", 0, 600),

	mimicTime          = CreateConVar("pulse_mimic_time", "30", SV_FLAGS, "Mimic: max duration in seconds", 5, 300),
	mimicCooldown      = CreateConVar("pulse_mimic_cooldown", "90", SV_FLAGS, "Mimic: cooldown in seconds", 0, 600),

	doorRadius         = CreateConVar("pulse_door_radius", "500", SV_FLAGS, "Door slam: radius in units", 100, 3000),
	doorLockTime       = CreateConVar("pulse_door_lock_time", "8", SV_FLAGS, "Door slam: doors stay locked for seconds", 1, 60),
	doorCooldown       = CreateConVar("pulse_door_cooldown", "40", SV_FLAGS, "Door slam: cooldown in seconds", 0, 600),
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
	{ id = "aim",      name = "Aim Assist",       kind = "toggle", feature = "aim", desc = "Pulls your crosshair toward visible victims." },
	{ id = "radar",    name = "Radar",            kind = "toggle", feature = "radar", desc = "See all victims through walls." },
	{ id = "noise",    name = "Noise Radar",      kind = "toggle", noPassive = true,
		desc = "Sprinting, jumping and shooting victims show up as pings. You can't sprint while it is on." },
	{ id = "tracks",   name = "Footprints",       kind = "toggle", desc = "Victims leave glowing footprints only you can see." },
	{ id = "heart",    name = "Heartbeat Sensor", kind = "toggle", desc = "A heartbeat that gets faster the closer a victim is." },
	{ id = "stalk",    name = "Stalk",            kind = "active", desc = "Watch the nearest victim for a few seconds. Your body stays frozen where it is." },
	{ id = "behind",   name = "Behind You",       kind = "active", desc = "Appear right behind the nearest victim. They hear breathing. If they turn around, you vanish." },
	{ id = "jump",     name = "Jump Scare",       kind = "active", desc = "Every victim nearby sees your face right in front of theirs." },
	{ id = "blackout", name = "Blackout",         kind = "active", desc = "Victims nearby lose their sight and flashlight for a few seconds." },
	{ id = "trap",     name = "Trap",             kind = "active", desc = "Place a trap where you look. It holds a victim and rattles loudly." },
	{ id = "mark",     name = "Mark",             kind = "active", desc = "Aim at a victim to keep them visible for a few seconds." },
	{ id = "mimic",    name = "Mimic",            kind = "active", desc = "Look like one of the victims until you attack." },
	{ id = "doorslam", name = "Door Slam",        kind = "active", feature = "doorslam", desc = "Slam and lock doors nearby for a moment (depends on the map)." },
	{ id = "nightvision", name = "Night Vision",  kind = "toggle", desc = "Grainy green vision that lights up a small area around you." },
}

HT.VictimAbilities = {
	{ id = "flash",      name = "Flashlight Blind", kind = "active",  slot = 1, allow = CV.allowFlash,
		desc = "Blinds the hunter if you light him up while he looks at you." },
	{ id = "silent",     name = "Stay Silent",      kind = "active",  slot = 2, allow = CV.allowSilent,
		desc = "For a few seconds the hunter can't find you: no radar, chaser pulse, marks, noise pings, footprints or heartbeat." },
	{ id = "decoy",      name = "Decoy",            kind = "active",  slot = 3, allow = CV.allowDecoy,
		desc = "Throw a can. The hunter gets a fake noise ping where it lands." },
	{ id = "adrenaline", name = "Adrenaline",       kind = "passive", allow = CV.allowAdrenaline,
		desc = "Short speed boost after the hunter hits you." },
	{ id = "hide",       name = "Hiding Bonus",     kind = "passive", allow = CV.allowHide,
		desc = "Crouch still for a while to vanish from radar and chaser pulse." },
	{ id = "vheart",     name = "Heartbeat",        kind = "toggle",  slot = 4, allow = CV.victimHeart,
		desc = "Hear your heart beat faster when a hunter is near. Switch it on or off." },
}

-- Features that are hidden by default and can be switched on in the developer menu (Game setting "features")
HT.HideableFeatures = {
	{ id = "aim",      name = "Aim Assist", default = false, desc = "Hunter ability, its personal settings and the server limits." },
	{ id = "radar",    name = "Radar",      default = false, desc = "Hunter ability: all victims through walls." },
	{ id = "doorslam", name = "Door Slam",  default = true,  desc = "Hunter ability: slam and lock doors (depends on the map)." },
}
HT.FeatureByID = {}
for _, feat in ipairs(HT.HideableFeatures) do HT.FeatureByID[feat.id] = feat end

-- Scary sound switched on in the developer menu?
function HT.ScaryEnabled(path)
	local off = HT.Game and HT.Game.scaryOff
	return not (istable(off) and off[path] == true)
end

function HT.FeatureOn(id)
	local f = HT.Game and HT.Game.features
	if istable(f) and f[id] ~= nil then return f[id] == true end
	return HT.FeatureByID[id] ~= nil and HT.FeatureByID[id].default
end

-- A hunter ability whose feature is switched off: not shown anywhere and doesn't work
function HT.AbilityHidden(id)
	local def = HT.AbilityByID[id]
	return def ~= nil and def.feature ~= nil and not HT.FeatureOn(def.feature)
end

-- Hunter abilities that are not hidden
function HT.VisibleHunterAbilities()
	local list = {}
	for _, def in ipairs(HT.HunterAbilities) do
		if not HT.AbilityHidden(def.id) then list[#list + 1] = def end
	end
	return list
end

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
-- Toggles with noPassive can't be "p": a saved "p" becomes menu only
------------------------------------------------------------------------

HT.DEFAULT_LOADOUT = "chaser=1;roar=2;stalk=3;nightvision=4;heart=m;tracks=p"
HT.DEFAULT_ROLE = "Default" -- the player's own setup (Hunter > Default)

function HT.ParseLoadout(str)
	local lo = { slots = {}, state = {}, menu = {} }
	for id, v in string.gmatch(str or "", "([%w_]+)=(%w+)") do
		local def = HT.AbilityByID[id]
		if def and def.hunter and not lo.state[id] and not HT.AbilityHidden(id) then
			local n = tonumber(v)
			if n and n >= 1 and n <= HT.SLOTS and not lo.slots[n] then
				lo.slots[n] = id
				lo.state[id] = n
			elseif v == "p" and def.kind == "toggle" and not def.noPassive then
				lo.state[id] = "p"
			elseif v == "m" or (v == "p" and def.kind == "toggle") then
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
	local key = s -- hidden abilities change the result
	for _, feat in ipairs(HT.HideableFeatures) do
		if HT.FeatureOn(feat.id) then key = key .. "|" .. feat.id end
	end
	local lo = loadoutCache[key]
	if not lo then
		lo = HT.ParseLoadout(s)
		loadoutCache[key] = lo
	end
	return lo
end

------------------------------------------------------------------------
-- Roles and game settings (synced from the server, saved in data/pulse/)
------------------------------------------------------------------------

HT.DefaultRoles = {
	{ name = "Stalker", loadout = "behind=1;sounds=2;teleport=3;roar=4;stalk=m;tracks=p;heart=p" },
	{ name = "Tracker", loadout = "chaser=1;roar=2;noise=3;sounds=4;stalk=m;tracks=p" },
	{ name = "Brute",   loadout = "roar=1;teleport=2;jump=3;chaser=4;heart=p" },
	{ name = "Seer",    loadout = "mark=1;chaser=2;jump=3;sounds=4;stalk=m;heart=p" },
	{ name = "Phantom", loadout = "mimic=1;blackout=2;trap=3;doorslam=4;mark=m;nightvision=p;heart=p" },
}

HT.GameDefaults = {
	version      = 2,            -- raised when saved game settings need a one-time update
	roundTime    = 480,          -- seconds victims must survive
	prepEnabled  = true,
	prepTime     = 30,           -- hiding phase, hunter frozen and blind
	hunterCount  = 1,
	hunterSelect = "random",     -- random | preselected
	roleMode     = "fixed",      -- fixed | choice | random
	fixedRole    = "Default",    -- "Default" = every hunter's own setup
	choiceTime   = 15,
	hunterWeapon = "weapon_crowbar",
	victimWeapons = "",          -- start weapons for victims, comma separated classes
	victimDamage = false,        -- victims may hurt the hunter with their weapons
	victimFriendlyFire = false,  -- victims may hurt each other

	-- voice chat during a round
	deadMute     = true,         -- dead players / spectators can't talk to the living (they still hear everyone)
	deadTalkDead = true,         -- dead players can talk to each other


	-- final phase and atmosphere
	finalPhase   = true,         -- last victim standing gets a speed boost, chase music starts
	finalBoost   = 5,            -- seconds of speed boost for the last victim
	musicLast    = 60,           -- chase music for everyone in the last seconds (0 = off)
	ambient      = true,         -- background sounds that get louder over the round
	ambientVolume = 0.5,

	-- items on the map
	items        = true,
	itemCount    = 8,
	itemPills    = true,
	itemGlowstick = true,
	itemCamera   = true,

	-- round series
	seriesMode   = "everyone",   -- everyone (each player hunter once) | fixed
	seriesRounds = 5,
	seriesDelay  = 15,           -- seconds between rounds

	-- test mode
	botsWalk     = false,

	-- scary sounds switched off in the developer menu (path = true); own files are on unless listed
	scaryOff     = {
		["ambient/creatures/teddy.wav"] = true,
		["ambient/voices/f_scream1.wav"] = true,
		["ambient/voices/m_scream1.wav"] = true,
		["npc/stalker/breathing3.wav"] = true,
		["ambient/levels/citadel/strange_talk3.wav"] = true,
		["npc/zombie/zombie_voice_idle1.wav"] = true,
	},

	-- hidden features switched on in the developer menu, e.g. { aim = true }
	features     = {},

	-- Pill Pack groups to hide in the character lists (nil = base packs hidden)
	pillHidden   = {},
}

HT.Items = {
	{ key = "itemPills",     class = "pulse_item_pills",     name = "Calming Pills" },
	{ key = "itemGlowstick", class = "pulse_item_glowstick", name = "Glowstick" },
	{ key = "itemCamera",    class = "pulse_item_camera",    name = "Camera Flash" },
}

HT.HunterWeapons = {
	{ "weapon_crowbar", "Crowbar" },
	{ "weapon_stunstick", "Stunstick" },
	{ "weapon_fists", "Fists" },
	{ "", "No weapon" },
}

-- Start weapons the admin can tick for victims (any other class can be typed in)
HT.VictimWeapons = {
	{ "weapon_crowbar", "Crowbar" },
	{ "weapon_stunstick", "Stunstick" },
	{ "weapon_pistol", "Pistol" },
	{ "weapon_357", ".357 Magnum" },
	{ "weapon_smg1", "SMG" },
	{ "weapon_shotgun", "Shotgun" },
	{ "weapon_ar2", "Pulse Rifle" },
	{ "weapon_crossbow", "Crossbow" },
	{ "weapon_frag", "Grenade" },
	{ "weapon_physcannon", "Gravity Gun" },
	{ "weapon_bugbait", "Bugbait" },
}

-- "weapon_pistol, weapon_smg1" -> { "weapon_pistol", "weapon_smg1" } (valid class names only, max 16)
function HT.VictimWeaponList(str)
	local list, seen = {}, {}
	for class in string.gmatch(tostring(str or ""), "[^,%s]+") do
		class = string.lower(class)
		if #class <= 64 and not string.find(class, "[^%w_%-%.]") and not seen[class] and #list < 16 then
			seen[class] = true
			list[#list + 1] = class
		end
	end
	return list
end

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
	{ key = "HT_DefPill",         type = "string", default = "" }, -- character for the Default role
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
-- Owner: host / superadmin. Only owners can give or take PULSE admin rights.
function HT.IsOwner(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if game.SinglePlayer() or ply:IsSuperAdmin() or ply:GetNWBool("HT_Owner", false) then return true end
	return SERVER and ply:IsListenServerHost() or false
end

-- Manager: owners plus players who got PULSE admin rights (Players, Server and Game tabs)
function HT.IsManager(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	return HT.IsOwner(ply) or ply:GetNWBool("HT_Admin", false)
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
	local def = HT.AbilityByID[id]
	if def and not def.hunter then -- victim toggles live on the client
		return HT.VictimToggleOn ~= nil and HT.VictimToggleOn(ply, id)
	end
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
-- Hidden from radar, chaser pulse and being revealed: hiding bonus or "Stay Silent"
function HT.IsHidden(ply)
	return (CV.allowHide:GetBool() and ply:GetNWBool("HT_Hidden", false)) or HT.IsSilent(ply)
end

function HT.FormatTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- Speed: roar slows, adrenaline speeds up (in SetupMove so it is predicted)
-- Frozen: hunters in the hiding phase, while stalking / behind a victim, or caught in a trap
function HT.IsFrozen(ply)
	if HT.IsHunter(ply) and HT.Phase() == "prep" then return true end
	return HT.IsActive(ply, "stalk") or HT.IsActive(ply, "behind") or ply:GetNWFloat("HT_RootUntil", 0) > CurTime()
end

-- Empty the player's input: works for normal players and for Pill Pack characters,
-- which move with their own system and ignore Player:Freeze()
hook.Add("StartCommand", "HT_Frozen", function(ply, cmd)
	if not HT.IsFrozen(ply) then return end
	cmd:ClearMovement()
	cmd:ClearButtons()
	-- Behind You: always look at the victim (also turns Pill Pack characters)
	local ang = HT.BehindAngle(ply)
	if ang then cmd:SetViewAngles(ang) end
end)

-- View angle toward the victim while standing behind them, or nil
function HT.BehindAngle(ply)
	if not HT.IsActive(ply, "behind") then return end
	local target = ply:GetNWEntity("HT_BehindTarget")
	if not IsValid(target) then return end
	local ang = (target:EyePos() - ply:EyePos()):Angle()
	ang.r = 0
	return ang
end

hook.Add("SetupMove", "HT_Speed", function(ply, mv)
	-- out of stamina: walking speed only
	if ply:GetNWBool("HT_Exhausted", false) then
		local walk = ply:GetWalkSpeed()
		mv:SetMaxClientSpeed(math.min(mv:GetMaxClientSpeed(), walk))
		mv:SetMaxSpeed(math.min(mv:GetMaxSpeed(), walk))
	end
	-- noise radar on or just hurt: the hunter can't sprint
	if HT.IsHunter(ply) and (HT.IsOn(ply, "noise") or ply:GetNWFloat("HT_HurtUntil", 0) > CurTime()) then
		local walk = ply:GetWalkSpeed()
		mv:SetMaxClientSpeed(math.min(mv:GetMaxClientSpeed(), walk))
		mv:SetMaxSpeed(math.min(mv:GetMaxSpeed(), walk))
	end
	if HT.IsFrozen(ply) then
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
	{ "Loud knock",                  "physics/wood/wood_crate_impact_hard3.wav", 3 }, -- 3 = knocks three times
}
