-- PULSE: every sound has its own folder in sound/pulse/<folder>/.
-- Files in a folder replace the default sound; with several files a random one plays each time.
-- Sounds without a default stay silent until you put a file into their folder.

local HT = Pulse

-- default: one path, or a list (random pick; all = play the whole list together)
-- pitch: number or { min, max } (only for the default sounds, own files play at 100)
HT.SoundSlots = {
	-- Hunter
	{ id = "behind",      group = "Hunter", name = "Behind You: behind the victim",   folder = "behindu/behind",   default = "npc/stalker/breathing3.wav" },
	{ id = "behind_turn", group = "Hunter", name = "Behind You: victim turns around", folder = "behindu/turn",     default = "npc/stalker/go_alert2a.wav", pitch = 60 },
	{ id = "roar",        group = "Hunter", name = "Roar",                            folder = "hunter/roar",      default = "npc/fast_zombie/fz_scream1.wav", pitch = 80 },
	{ id = "teleport",    group = "Hunter", name = "Teleport",                        folder = "hunter/teleport",  default = "npc/stalker/go_alert2a.wav", pitch = 70 },
	{ id = "chaser",      group = "Hunter", name = "Chaser Pulse (only the hunter)",  folder = "hunter/chaser",    default = "ambient/levels/citadel/weapon_disintegrate2.wav" },
	{ id = "jumpscare",   group = "Hunter", name = "Jump Scare (the victim hears it)", folder = "hunter/jumpscare", default = { "npc/fast_zombie/fz_scream1.wav", "npc/zombie/zombie_pain6.wav" }, all = true },
	{ id = "blackout",    group = "Hunter", name = "Blackout",                        folder = "hunter/blackout",  default = "ambient/energy/power_off1.wav", pitch = 80 },
	{ id = "doorslam",    group = "Hunter", name = "Door Slam",                       folder = "hunter/doorslam",  default = "doors/heavy_metal_stop1.wav", pitch = { 90, 110 } },
	{ id = "trap",        group = "Hunter", name = "Trap snaps shut",                 folder = "hunter/trap",      default = { "physics/metal/metal_chainlink_impact_hard1.wav", "physics/metal/metal_box_impact_hard1.wav" }, all = true },
	{ id = "trap_place",  group = "Hunter", name = "Trap placed",                     folder = "hunter/trap_place" },
	{ id = "stalk",       group = "Hunter", name = "Stalk starts (only the hunter)",  folder = "hunter/stalk" },
	{ id = "mark",        group = "Hunter", name = "Marked (the victim hears it)",    folder = "hunter/mark" },
	{ id = "mimic",       group = "Hunter", name = "Mimic starts",                    folder = "hunter/mimic" },
	{ id = "nightvision", group = "Hunter", name = "Night Vision on (only the hunter)", folder = "hunter/nightvision" },
	{ id = "ping",        group = "Hunter", name = "Noise Radar ping (only the hunter)", folder = "hunter/ping" },
	{ id = "heartbeat",   group = "Hunter", name = "Heartbeat (sensor and victims)",  folder = "heartbeat",        default = "pulse_fx/heartbeat.wav" },
	{ id = "toggle",      group = "Hunter", name = "Ability on / off",                folder = "ui/toggle",        default = "buttons/blip1.wav" },

	-- Victim
	{ id = "flash",       group = "Victim", name = "Flashlight Blind",                folder = "victim/flash",     default = "items/flashlight1.wav", pitch = 90 },
	{ id = "blinded",     group = "Victim", name = "Hunter is blinded (the hunter hears it)", folder = "victim/blinded", default = "ambient/energy/zap1.wav" },
	{ id = "silent",      group = "Victim", name = "Stay Silent",                     folder = "victim/silent",    default = "npc/zombie/foot_slide1.wav" },
	{ id = "decoy",       group = "Victim", name = "Decoy thrown",                    folder = "victim/decoy",     default = "weapons/slam/throw.wav" },
	{ id = "decoy_land",  group = "Victim", name = "Decoy lands",                     folder = "victim/decoy_land", default = { "physics/metal/soda_can_impact_hard1.wav", "physics/metal/soda_can_impact_hard2.wav", "physics/metal/soda_can_impact_hard3.wav" } },
	{ id = "adrenaline",  group = "Victim", name = "Adrenaline",                      folder = "victim/adrenaline" },
	{ id = "exhausted",   group = "Victim", name = "Out of stamina",                  folder = "victim/exhausted" },
	{ id = "hidden",      group = "Victim", name = "Hiding bonus active",             folder = "victim/hidden" },

	-- Items
	{ id = "item_pickup", group = "Items", name = "Item picked up",                   folder = "items/pickup" },
	{ id = "pills",       group = "Items", name = "Calming Pills",                    folder = "items/pills",      default = "npc/barnacle/barnacle_gulp1.wav" },
	{ id = "glowstick",   group = "Items", name = "Glowstick",                        folder = "items/glowstick",  default = "weapons/slam/throw.wav" },
	{ id = "camera",      group = "Items", name = "Camera Flash",                     folder = "items/camera",     default = "npc/scanner/scanner_photo1.wav" },

	-- Sanity
	{ id = "whisper",     group = "Sanity", name = "Hallucination whispers",          folder = "sanity/whispers",  pitch = { 80, 110 }, default = {
		"ambient/levels/citadel/strange_talk1.wav", "ambient/levels/citadel/strange_talk3.wav", "ambient/levels/citadel/strange_talk5.wav",
		"ambient/voices/playground_memory.wav", "npc/stalker/breathing3.wav" } },

	-- Round
	{ id = "prep",        group = "Round", name = "Hiding phase starts",              folder = "round/prep" },
	{ id = "hunt",        group = "Round", name = "The hunt begins",                  folder = "round/hunt" },
	{ id = "final",       group = "Round", name = "Final phase begins",               folder = "round/final" },
	{ id = "caught",      group = "Round", name = "Victim caught / died",             folder = "round/caught" },
	{ id = "win_hunter",  group = "Round", name = "Hunter wins",                      folder = "round/win_hunter", default = "ambient/creatures/town_child_scream1.wav" },
	{ id = "win_victims", group = "Round", name = "Victims win",                      folder = "round/win_victims", default = "ambient/levels/citadel/strange_talk1.wav" },
	{ id = "click",       group = "Round", name = "Menu click",                       folder = "ui/click",         default = "buttons/button14.wav" },
}

HT.SoundByID = {}
for _, s in ipairs(HT.SoundSlots) do HT.SoundByID[s.id] = s end

local EXT = { wav = true, mp3 = true, ogg = true }

-- Own files in sound/pulse/<folder>/ (paths without "sound/")
function HT.SoundFolderFiles(folder)
	local list = {}
	local dir = folder == "" and "pulse/" or ("pulse/" .. folder .. "/")
	local files = file.Find("sound/" .. dir .. "*", "GAME") or {}
	table.sort(files)
	for _, f in ipairs(files) do
		if EXT[string.lower(string.GetExtensionFromFilename(f) or "")] then list[#list + 1] = dir .. f end
	end
	return list
end

local ownCache = {}
function HT.OwnSounds(id)
	if not ownCache[id] then
		local slot = HT.SoundByID[id]
		ownCache[id] = slot and HT.SoundFolderFiles(slot.folder) or {}
	end
	return ownCache[id]
end

local function Pitch(p)
	if istable(p) then return math.random(p[1], p[2]) end
	return p or 100
end

-- What to play now: { { path, pitch }, ... } (empty = silent)
function HT.SoundPick(id)
	local own = HT.OwnSounds(id)
	if #own > 0 then return { { own[math.random(#own)], 100 } } end
	local slot = HT.SoundByID[id]
	local def = slot and slot.default
	if not def then return {} end
	if isstring(def) then return { { def, Pitch(slot.pitch) } } end
	if slot.all then
		local out = {}
		for _, path in ipairs(def) do out[#out + 1] = { path, Pitch(slot.pitch) } end
		return out
	end
	return { { def[math.random(#def)], Pitch(slot.pitch) } }
end

-- Plays on an entity; returns how long the (first) sound lasts
function HT.EmitSlot(ent, id, level, volume, channel)
	local len = 0
	for _, s in ipairs(HT.SoundPick(id)) do
		ent:EmitSound(s[1], level or 75, s[2], volume or 1, channel or CHAN_STATIC)
		if len == 0 then len = SoundDuration(s[1]) or 0 end
	end
	return len
end

-- Plays at a position in the world; returns how long the (first) sound lasts
function HT.PlaySlotAt(id, pos, level, volume)
	local len = 0
	for _, s in ipairs(HT.SoundPick(id)) do
		sound.Play(s[1], pos, level or 75, s[2], volume or 1)
		if len == 0 then len = SoundDuration(s[1]) or 0 end
	end
	return len
end

if SERVER then
	util.AddNetworkString("HT_PlaySlot")

	-- friends download every own sound when joining
	for _, slot in ipairs(HT.SoundSlots) do
		for _, path in ipairs(HT.OwnSounds(slot.id)) do resource.AddFile("sound/" .. path) end
	end
	for _, folder in ipairs({ "music", "ambient", "stingers", "scary" }) do
		for _, path in ipairs(HT.SoundFolderFiles(folder)) do resource.AddFile("sound/" .. path) end
	end

	-- Only these players hear it (like a sound in their head)
	function HT.SendSlot(id, recipients)
		if #HT.SoundPick(id) == 0 then return end
		net.Start("HT_PlaySlot")
		net.WriteString(id)
		if recipients then net.Send(recipients) else net.Broadcast() end
	end
else
	-- A sound only you hear
	function HT.PlaySlotLocal(id, volume)
		local me = LocalPlayer()
		for _, s in ipairs(HT.SoundPick(id)) do
			if s[2] == 100 and not volume then
				surface.PlaySound(s[1])
			elseif IsValid(me) then
				me:EmitSound(s[1], 75, s[2], volume or 1, CHAN_STATIC)
			end
		end
	end

	net.Receive("HT_PlaySlot", function() HT.PlaySlotLocal(net.ReadString()) end)
end
