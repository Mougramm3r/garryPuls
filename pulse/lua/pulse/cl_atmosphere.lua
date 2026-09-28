-- PULSE: atmosphere (chase music, ambient sounds), night vision, blackout, series HUD

local HT = Pulse
local C = HT.Colors
local LP = HT.LP

-- First file that exists: own files in sound/pulse/<folder>/ win over the built-in ones
local function PickSound(folder, builtin)
	local own = file.Find("sound/pulse/" .. folder .. "/*", "GAME")
	local list = {}
	for _, f in ipairs(own or {}) do
		local ext = string.lower(string.GetExtensionFromFilename(f) or "")
		if ext == "mp3" or ext == "wav" or ext == "ogg" then list[#list + 1] = "sound/pulse/" .. folder .. "/" .. f end
	end
	if #list == 0 then
		for _, p in ipairs(builtin) do
			if file.Exists("sound/" .. p, "GAME") then list[#list + 1] = "sound/" .. p end
		end
	end
	return list
end

local MUSIC_BUILTIN = {
	"music/hl2_song3.mp3", "music/hl2_song20_submix0.mp3", "music/hl2_song29.mp3",
	"music/hl2_song12_long.mp3", "music/hl1_song10.mp3",
}
local AMBIENT_BUILTIN = {
	"ambient/atmosphere/tone_quiet.wav", "ambient/atmosphere/noise2.wav",
	"ambient/atmosphere/cave_outdoor1.wav", "ambient/levels/citadel/citadel_ambient_scream_loop1.wav",
}
local STINGERS = {
	"ambient/creatures/town_moan1.wav", "ambient/atmosphere/hole_hit1.wav", "ambient/atmosphere/cave_hit1.wav",
	"ambient/creatures/town_zombie_call1.wav", "ambient/levels/citadel/strange_talk1.wav",
}

-- A looping sound channel we can fade in and out
local function Track(name)
	return { name = name, chan = nil, loading = false, vol = 0, target = 0 }
end

local music, ambient = Track("music"), Track("ambient")

local function UpdateTrack(t, files, target)
	t.target = target
	if target > 0 and not t.chan and not t.loading and #files > 0 then
		t.loading = true
		sound.PlayFile(files[math.random(#files)], "noblock", function(chan)
			t.loading = false
			if not IsValid(chan) then return end
			chan:EnableLooping(true)
			chan:SetVolume(0)
			chan:Play()
			t.chan = chan
		end)
	end
	if IsValid(t.chan) then
		t.vol = math.Approach(t.vol, t.target, FrameTime() * 0.5)
		t.chan:SetVolume(t.vol)
		if t.vol <= 0 and t.target <= 0 then
			t.chan:Stop()
			t.chan = nil
		end
	end
end

local musicFiles, ambientFiles, stingerFiles
local nextStinger = 0

hook.Add("Think", "HT_Atmosphere", function()
	local me = LP()
	if not me then return end
	musicFiles = musicFiles or PickSound("music", MUSIC_BUILTIN)
	ambientFiles = ambientFiles or PickSound("ambient", AMBIENT_BUILTIN)
	stingerFiles = stingerFiles or PickSound("stingers", STINGERS)

	local g = HT.Game
	local hunt = HT.Phase() == "hunt"
	local left = HT.PhaseEnd() - CurTime()

	-- chase music: final phase (hunter and the last victim) and the last seconds for everyone
	local wantMusic = false
	if hunt then
		if GetGlobalBool("HT_Final", false) and (HT.IsHunter(me) or HT.IsVictim(me)) then wantMusic = true end
		if (g.musicLast or 0) > 0 and left <= g.musicLast then wantMusic = true end
	end
	UpdateTrack(music, musicFiles, wantMusic and 0.8 or 0)

	-- ambient: quiet at the start, louder the longer the round runs
	local ambientVol = 0
	if g.ambient and HT.InRound() then
		local progress = hunt and math.Clamp(1 - left / math.max(1, g.roundTime), 0, 1) or 0
		ambientVol = (g.ambientVolume or 0.5) * (0.25 + 0.75 * progress)
		if wantMusic then ambientVol = ambientVol * 0.4 end

		if hunt and CurTime() > nextStinger and #stingerFiles > 0 then
			nextStinger = CurTime() + math.random(25, 60)
			local path = string.sub(stingerFiles[math.random(#stingerFiles)], 7) -- without "sound/"
			me:EmitSound(path, 60, math.random(85, 105), math.Clamp(ambientVol + 0.2, 0.2, 1), CHAN_STATIC)
		end
	end
	UpdateTrack(ambient, ambientFiles, ambientVol)
end)

------------------------------------------------------------------------
-- Blackout (victims) and night vision (hunter)
------------------------------------------------------------------------

local blackoutUntil, blackoutTime = 0, 1

net.Receive("HT_Blackout", function()
	blackoutTime = net.ReadFloat()
	blackoutUntil = CurTime() + blackoutTime
	surface.PlaySound("ambient/energy/power_off1.wav")
end)

hook.Add("RenderScreenspaceEffects", "HT_BlackoutNV", function()
	local me = LP()
	if not me then return end

	local left = blackoutUntil - CurTime()
	if left > 0 then
		local k = math.Clamp(left / math.min(blackoutTime, 1.5), 0, 1)
		DrawColorModify({
			["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = -0.45 * k, ["$pp_colour_contrast"] = 1 - 0.4 * k,
			["$pp_colour_colour"] = 1 - 0.8 * k,
			["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
		})
	end

	if HT.IsOn(me, "nightvision") then
		DrawColorModify({
			["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.08, ["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = 0.12, ["$pp_colour_contrast"] = 1.3,
			["$pp_colour_colour"] = 0.25,
			["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0.4, ["$pp_colour_mulb"] = 0,
		})
	end
end)

hook.Add("Think", "HT_NightVisionLight", function()
	local me = LP()
	if not me or not HT.IsOn(me, "nightvision") then return end
	local light = DynamicLight(me:EntIndex() + 4096)
	if light then
		light.pos = me:EyePos()
		light.r, light.g, light.b = 140, 255, 140
		light.brightness = 0.6
		light.decay = 2000
		light.size = 1400
		light.dietime = CurTime() + 0.2
	end
end)

------------------------------------------------------------------------
-- No name tags during a round (it would give away Mimic and hiding spots)
------------------------------------------------------------------------

hook.Add("HUDDrawTargetID", "HT_NoTargetID", function()
	if HT.InRound() then return false end
end)

------------------------------------------------------------------------
-- Series info and the countdown to the next round
------------------------------------------------------------------------

hook.Add("HUDPaint", "HT_SeriesHUD", function()
	local series = HT.SeriesInfo
	local x = ScrW() / 2
	if HT.InRound() then
		if series and series.active and series.total > 0 then
			draw.SimpleTextOutlined(string.format("ROUND %d / %d", series.round + 1, series.total), "HT_Row", 20, 20,
				C.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
		end
		if GetGlobalBool("HT_Final", false) then
			draw.SimpleTextOutlined("FINAL PHASE", "HT_Sub", x, 128, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
		end
		return
	end

	local nextRound = GetGlobalFloat("HT_NextRound", 0) - CurTime()
	if nextRound > 0 then
		draw.SimpleTextOutlined("NEXT ROUND IN " .. math.ceil(nextRound), "HT_Sub", x, 20, C.warn,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
	end
end)
