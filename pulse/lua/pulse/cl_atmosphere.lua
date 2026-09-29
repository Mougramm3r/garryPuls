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
	HT.PlaySlotLocal("blackout")
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

	-- night vision: green, no extra brightness far away (only the small light around the hunter)
	if HT.IsOn(me, "nightvision") then
		local flicker = math.sin(CurTime() * 23) * 0.01 + math.Rand(-0.01, 0.01)
		DrawColorModify({
			["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0.03, ["$pp_colour_addb"] = 0,
			["$pp_colour_brightness"] = flicker, ["$pp_colour_contrast"] = 1.15,
			["$pp_colour_colour"] = 0.1,
			["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0.3, ["$pp_colour_mulb"] = 0,
		})
		DrawMotionBlur(0.35, 0.6, 0.01)
	end
end)

-- The light only reaches a small radius (Server tab: "Night vision: light radius")
hook.Add("Think", "HT_NightVisionLight", function()
	local me = LP()
	if not me or not HT.IsOn(me, "nightvision") then return end
	local light = DynamicLight(me:EntIndex() + 4096)
	if light then
		light.pos = me:EyePos()
		light.r, light.g, light.b = 120, 255, 120
		light.brightness = 1.2
		light.decay = 3000
		light.size = HT.CV.nvRadius:GetFloat()
		light.dietime = CurTime() + 0.2
	end
end)

-- Blurry, grainy picture with scanlines and dark edges, like an old night vision camera
local blurMat = Material("pp/blurscreen")

hook.Add("HUDPaintBackground", "HT_NightVisionFX", function()
	local me = LP()
	if not me or not HT.IsOn(me, "nightvision") then return end
	local w, h = ScrW(), ScrH()

	-- soft blur
	surface.SetMaterial(blurMat)
	surface.SetDrawColor(255, 255, 255, 255)
	for i = 1, 2 do
		blurMat:SetFloat("$blur", i * 0.8)
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(0, 0, w, h)
	end

	-- grain
	for _ = 1, 700 do
		local v = math.random(0, 1) * 200
		surface.SetDrawColor(v * 0.6, v, v * 0.6, math.random(20, 60))
		local size = math.random(1, 3)
		surface.DrawRect(math.random(0, w), math.random(0, h), size, size)
	end

	-- scanlines and a slow rolling band
	surface.SetDrawColor(0, 0, 0, 70)
	for y = 0, h, 4 do surface.DrawRect(0, y, w, 2) end
	local band = (CurTime() * 90) % (h + 120) - 60
	surface.SetDrawColor(160, 255, 160, 10)
	surface.DrawRect(0, band, w, 40)

	-- vignette
	local steps = 16
	local bw, bh = w * 0.2 / steps, h * 0.2 / steps
	surface.SetDrawColor(0, 0, 0, 28)
	for i = 0, steps - 1 do
		local x, y = i * bw, i * bh
		surface.DrawRect(x, y, w - 2 * x, bh)           -- top
		surface.DrawRect(x, h - y - bh, w - 2 * x, bh)  -- bottom
		surface.DrawRect(x, y + bh, bw, h - 2 * y - 2 * bh)       -- left
		surface.DrawRect(w - x - bw, y + bh, bw, h - 2 * y - 2 * bh) -- right
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

------------------------------------------------------------------------
-- Spectator info
------------------------------------------------------------------------

-- Our own camera for dead players / spectators: follow a living player or fly freely.
-- (GMod's death camera would stay inside the own body: dark, red and blurry.)
local spec = { pos = nil, ang = nil, target = nil, keys = {}, nextSend = 0 }

local function Spectating(me)
	return HT.InRound() and (not me:Alive() or me:GetNWBool("HT_Spectator", false))
end
HT.Spectating = Spectating

local function LivingPlayers(me)
	local list = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply ~= me and ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE and not ply:GetNWBool("HT_Spectator", false) then
			list[#list + 1] = ply
		end
	end
	table.sort(list, function(a, b) return a:EntIndex() < b:EntIndex() end)
	return list
end

local function Pressed(name, down)
	local was = spec.keys[name]
	spec.keys[name] = down
	return down and not was
end

local function BindDown(bind)
	local key = input.LookupBinding(bind)
	local code = key and input.GetKeyCode(key)
	return code and code > 0 and input.IsButtonDown(code) or false
end

hook.Add("Think", "HT_SpectatorCam", function()
	local me = LP()
	if not me or not Spectating(me) then
		spec.pos, spec.ang, spec.target = nil, nil, nil
		return
	end
	spec.ang = spec.ang or me:EyeAngles()
	spec.pos = spec.pos or me:EyePos()

	local blocked = vgui.GetKeyboardFocus() or gui.IsGameUIVisible() or (HT.AnyWindowOpen and HT.AnyWindowOpen())
	local left = Pressed("l", not blocked and input.IsMouseDown(MOUSE_LEFT))
	local right = Pressed("r", not blocked and input.IsMouseDown(MOUSE_RIGHT))
	local jump = Pressed("j", not blocked and BindDown("+jump"))

	-- left / right click: next / previous living player, space: free camera
	if left or right then
		local list = LivingPlayers(me)
		if #list > 0 then
			local index = 0
			for i, ply in ipairs(list) do if ply == spec.target then index = i end end
			index = index + (left and 1 or -1)
			if index < 1 then index = #list elseif index > #list then index = 1 end
			spec.target = list[index]
		end
	elseif jump then
		spec.target = nil
	end
	if IsValid(spec.target) and not spec.target:Alive() then spec.target = nil end

	-- free camera: fly with the movement keys
	if not IsValid(spec.target) and not blocked then
		local speed = (BindDown("+speed") and 900 or 400) * FrameTime()
		local fwd, rgt = spec.ang:Forward(), spec.ang:Right()
		local move = Vector(0, 0, 0)
		if BindDown("+forward") then move = move + fwd end
		if BindDown("+back") then move = move - fwd end
		if BindDown("+moveright") then move = move + rgt end
		if BindDown("+moveleft") then move = move - rgt end
		if BindDown("+duck") then move.z = move.z - 1 end
		spec.pos = spec.pos + move * speed
	end

	-- tell the server where we look, so things there are sent to us
	if CurTime() > spec.nextSend then
		spec.nextSend = CurTime() + 0.3
		net.Start("HT_SpecCam")
		net.WriteVector(IsValid(spec.target) and spec.target:GetPos() or spec.pos)
		net.SendToServer()
	end
end)

-- mouse look, also while dead
hook.Add("CreateMove", "HT_SpectatorLook", function(cmd)
	local me = LP()
	if not me or not Spectating(me) or not spec.ang then return end
	if vgui.CursorVisible() then return end
	local sens = GetConVar("sensitivity"):GetFloat() * 0.022
	spec.ang.p = math.Clamp(spec.ang.p + cmd:GetMouseY() * sens, -89, 89)
	spec.ang.y = spec.ang.y - cmd:GetMouseX() * sens
	spec.ang.r = 0
end)

hook.Add("CalcView", "HT_SpectatorView", function(ply, _, _, fov)
	if not Spectating(ply) or not spec.pos then return end
	local origin = spec.pos
	if IsValid(spec.target) then
		local eye = spec.target:EyePos()
		local tr = util.TraceHull({ start = eye, endpos = eye - spec.ang:Forward() * 110,
			mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6), mask = MASK_SOLID_BRUSHONLY })
		origin = tr.HitPos
		spec.pos = origin -- space keeps the camera here
	end
	return { origin = origin, angles = spec.ang, fov = fov, drawviewer = false }
end)

hook.Add("GetMotionBlurValues", "HT_SpectatorNoBlur", function()
	local me = LP()
	if me and Spectating(me) then return 0, 0, 0, 0 end
end)

hook.Add("HUDPaint", "HT_SpectatorHUD", function()
	local me = LP()
	if not me or not Spectating(me) then return end
	local target = spec.target
	local text = IsValid(target) and ("SPECTATING " .. string.upper(target:Nick())) or "SPECTATING (FREE CAMERA)"
	draw.SimpleTextOutlined(text, "HT_Sub", ScrW() / 2, ScrH() - 70, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	draw.SimpleTextOutlined("Left / right click: switch player   ·   Space: free camera (WASD, Shift = faster)", "HT_Row", ScrW() / 2, ScrH() - 46,
		C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	if HT.Game.deadMute then
		local text2 = HT.Game.deadTalkDead and "The living can't hear you. Other dead players can." or "Nobody can hear you until the round ends."
		draw.SimpleTextOutlined(text2, "HT_Row", ScrW() / 2, ScrH() - 24, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end)

------------------------------------------------------------------------
-- Voice chat: also mute dead players on this client (works even when another addon
-- or sv_alltalk decides on the server who hears whom). Only players we muted get unmuted again.
------------------------------------------------------------------------

local autoMuted = {} -- SteamID64 -> true
for id in string.gmatch(cookie.GetString("pulse_automuted", ""), "[^,]+") do autoMuted[id] = true end

local function SaveAutoMuted()
	cookie.Set("pulse_automuted", table.concat(table.GetKeys(autoMuted), ","))
end

timer.Create("HT_DeadVoiceClient", 0.5, 0, function()
	local me = LP()
	if not me then return end
	local changed = false
	for _, ply in ipairs(player.GetAll()) do
		if ply ~= me and not ply:IsBot() then
			local id = ply:SteamID64() or ""
			local block = HT.VoiceBlocked(me, ply)
			if block and not ply:IsMuted() then
				ply:SetMuted(true)
				autoMuted[id] = true
				changed = true
			elseif not block and autoMuted[id] then
				if ply:IsMuted() then ply:SetMuted(false) end
				autoMuted[id] = nil
				changed = true
			end
		end
	end
	if changed then SaveAutoMuted() end
end)
