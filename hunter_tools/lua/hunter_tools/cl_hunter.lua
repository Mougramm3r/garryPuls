-- Hunter Tools: client (keys, abilities, effects, HUD)

local HT = HunterTools
local CV = HT.CV
local Get = HT.Get

surface.CreateFont("HT_Timer", { font = "Roboto", size = 64, weight = 800 })
surface.CreateFont("HT_Sub", { font = "Roboto", size = 18, weight = 700 })
surface.CreateFont("HT_Row", { font = "Roboto", size = 16, weight = 500 })
surface.CreateFont("HT_RowBold", { font = "Roboto", size = 16, weight = 800 })
surface.CreateFont("HT_Key", { font = "Roboto Mono", size = 13, weight = 600 })
surface.CreateFont("HT_Big", { font = "Roboto", size = 42, weight = 800 })

HT.Colors = {
	panel = Color(16, 12, 13, 215),
	line = Color(58, 46, 47),
	text = Color(236, 228, 223),
	muted = Color(160, 146, 141),
	faint = Color(111, 98, 94),
	accent = Color(184, 50, 42),
	cold = Color(116, 182, 200),
	good = Color(134, 192, 127),
	warn = Color(217, 164, 65),
}
local C = HT.Colors

-- Keys (only for you, saved)
HT.Keys = {
	menu = CreateClientConVar("ht_key_menu", tostring(KEY_F5), true, false, "Key: open menu"),
}
for i = 1, HT.SLOTS do
	HT.Keys["slot" .. i] = CreateClientConVar("ht_key_slot" .. i, tostring(KEY_PAD_0 + i), true, false, "Key: ability slot " .. i)
end
HT.KeyDefaults = { menu = KEY_F5, slot1 = KEY_PAD_1, slot2 = KEY_PAD_2, slot3 = KEY_PAD_3, slot4 = KEY_PAD_4 }

HT.SoundMode = CreateClientConVar("ht_sound_mode", "2", true, false, "Scary sounds: where to play (1-4)", 1, 4)

function HT.KeyName(code)
	code = tonumber(code) or 0
	if code <= 0 then return "—" end
	if code >= KEY_PAD_0 and code <= KEY_PAD_9 then return "NUM " .. (code - KEY_PAD_0) end
	return string.upper(input.GetKeyName(code) or "?")
end

function HT.Notify(msg)
	chat.AddText(C.accent, "[Hunter] ", color_white, msg)
end

local function LP()
	local ply = LocalPlayer()
	return IsValid(ply) and ply or nil
end
HT.LP = LP

------------------------------------------------------------------------
-- Data from the server: roles and game settings
------------------------------------------------------------------------

net.Receive("HT_Data", function()
	local data = util.JSONToTable(net.ReadString())
	if not istable(data) then return end
	HT.Roles = data.roles or HT.Roles
	HT.Game = data.game or HT.Game
	hook.Run("HT_DataUpdated")
end)

------------------------------------------------------------------------
-- Personal settings (sent to the server, remembered between sessions)
------------------------------------------------------------------------

function HT.SendSetting(target, key, value, instant)
	if isbool(value) then value = value and "1" or "0" end
	value = tostring(value)
	local function send()
		if not IsValid(target) then return end
		net.Start("HT_Set")
		net.WriteEntity(target)
		net.WriteString(key)
		net.WriteString(value)
		net.SendToServer()
	end
	if instant then send() return end
	-- wait a moment so dragging a slider doesn't send every step
	timer.Create("HT_Set_" .. target:EntIndex() .. key, 0.2, 1, send)
end

local restored = false

hook.Add("InitPostEntity", "HT_Restore", function()
	timer.Simple(2, function()
		local me = LP()
		if not me then return end
		for _, s in ipairs(HT.Settings) do
			local saved = cookie.GetString("ht2_" .. s.key)
			if saved then HT.SendSetting(me, s.key, saved, true) end
		end
		restored = true
	end)
end)

timer.Create("HT_Save", 3, 0, function()
	local me = LP()
	if not me or not restored then return end
	for _, s in ipairs(HT.Settings) do
		local v = Get(me, s.key)
		cookie.Set("ht2_" .. s.key, isbool(v) and (v and "1" or "0") or tostring(v))
	end
end)

------------------------------------------------------------------------
-- Using abilities
------------------------------------------------------------------------

HT.LastUsed = nil -- shown in the HUD status line

function HT.UseAbility(id)
	local me = LP()
	local def = HT.AbilityByID[id]
	if not me or not def then return end

	if def.hunter then
		if not HT.HunterCanAct(me) then HT.Notify("You can't use abilities right now.") return end
		if def.kind == "toggle" then
			local on = not HT.IsOn(me, id)
			net.Start("HT_Ability")
			net.WriteString(id)
			net.SendToServer()
			surface.PlaySound("buttons/blip1.wav")
			HT.Notify(def.name .. (on and " ON" or " OFF"))
			return
		end
	else
		if not HT.IsVictim(me) then return end
		if not def.allow:GetBool() then HT.Notify(def.name .. " is disabled on this server.") return end
	end

	local wait = HT.ReadyIn(me, id)
	if wait > 0 then
		HT.Notify(string.format("%s is not ready (%.0fs)", def.name, wait))
		return
	end

	if id == "sounds" then
		if HT.OpenSoundPicker then HT.OpenSoundPicker() end
		return
	end

	net.Start("HT_Ability")
	net.WriteString(id)
	net.SendToServer()
	HT.LastUsed = id

	if id == "chaser" then surface.PlaySound("ambient/levels/citadel/weapon_disintegrate2.wav")
	elseif id == "silent" then surface.PlaySound("npc/zombie/foot_slide1.wav")
	elseif id == "decoy" then surface.PlaySound("weapons/slam/throw.wav") end
end

-- What is on slot n for me right now (hunter loadout or victim abilities)
function HT.SlotAbility(ply, n)
	if HT.IsHunter(ply) then
		local id = HT.Loadout(ply).slots[n]
		return id and HT.AbilityByID[id]
	end
	local def = HT.VictimSlots[n]
	if def and def.allow:GetBool() then return def end
end

function HT.UseSlot(n)
	local me = LP()
	if not me then return end
	local def = HT.SlotAbility(me, n)
	if not def then
		if HT.IsHunter(me) then HT.Notify("Slot " .. n .. " is empty.") end
		return
	end
	HT.UseAbility(def.id)
end

------------------------------------------------------------------------
-- Scary sounds
------------------------------------------------------------------------

HT.SoundNames = {}

net.Receive("HT_SoundList", function()
	HT.SoundNames = {}
	for i = 1, net.ReadUInt(8) do HT.SoundNames[i] = net.ReadString() end
end)

function HT.RequestSoundList()
	net.Start("HT_SoundPlay")
	net.WriteUInt(0, 8)
	net.WriteUInt(0, 3)
	net.SendToServer()
end

net.Receive("HT_SoundGlobal", function()
	surface.PlaySound(net.ReadString())
end)

function HT.PlayScarySound(index)
	local me = LP()
	if not me or not HT.SoundNames[index] then return end
	local mode = HT.SoundMode:GetInt()
	if mode == 4 and not CV.soundAllowGlobal:GetBool() then
		HT.Notify("The 'everywhere' mode is disabled on this server.")
		return
	end
	net.Start("HT_SoundPlay")
	net.WriteUInt(index, 8)
	net.WriteUInt(mode, 3)
	net.SendToServer()
	HT.LastUsed = "sounds"
end

------------------------------------------------------------------------
-- Keys
------------------------------------------------------------------------

local wasDown = {}

local function JustPressed(cvar)
	local key = cvar:GetInt()
	local down = key > 0 and input.IsButtonDown(key)
	local pressed = down and not wasDown[cvar]
	wasDown[cvar] = down
	return pressed
end

hook.Add("Think", "HT_Keys", function()
	local me = LP()
	if not me then return end

	-- always poll every key so nothing fires late when a block ends
	local pressed = {}
	for name, cvar in pairs(HT.Keys) do pressed[name] = JustPressed(cvar) end

	if input.IsKeyTrapping() or gui.IsGameUIVisible() or gui.IsConsoleVisible() or me:IsTyping() then return end

	if pressed.menu and HT.OpenMenu then HT.OpenMenu() end
	if HT.AnyWindowOpen and HT.AnyWindowOpen() then return end

	for i = 1, HT.SLOTS do
		if pressed["slot" .. i] then HT.UseSlot(i) end
	end
end)

------------------------------------------------------------------------
-- Targets
------------------------------------------------------------------------

local function Targets()
	local me, list = LP(), {}
	if not me then return list end
	for _, ply in ipairs(player.GetAll()) do
		if HT.IsTarget(me, ply) and not ply:IsDormant() then list[#list + 1] = ply end
	end
	return list
end

-- radar and chaser don't show hidden victims
local function SenseTargets()
	local list = {}
	for _, ply in ipairs(Targets()) do
		if not HT.IsHidden(ply) then list[#list + 1] = ply end
	end
	return list
end

local npcCache, npcCacheTime = {}, 0
local function NPCTargets()
	if CurTime() - npcCacheTime > 0.5 then
		npcCacheTime = CurTime()
		npcCache = {}
		for _, ent in ipairs(ents.GetAll()) do
			if (ent:IsNPC() or ent:IsNextBot()) and ent:Health() > 0 then npcCache[#npcCache + 1] = ent end
		end
	end
	local list = {}
	for _, ent in ipairs(npcCache) do
		if IsValid(ent) and not ent:IsDormant() and ent:Health() > 0 then list[#list + 1] = ent end
	end
	return list
end

------------------------------------------------------------------------
-- Aim assist
------------------------------------------------------------------------

local aimTarget

local function AimPoint(ent)
	local bone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine2")
	if bone then
		local pos = ent:GetBonePosition(bone)
		if pos and pos ~= ent:GetPos() then return pos end
	end
	return ent:WorldSpaceCenter()
end

local function FindAimTarget(me, eye, forward, maxFov)
	local candidates = Targets()
	if Get(me, "HT_AimNPC") then
		for _, npc in ipairs(NPCTargets()) do candidates[#candidates + 1] = npc end
	end

	local best, bestPos, bestAng
	for _, ent in ipairs(candidates) do
		local pos = AimPoint(ent)
		local dir = pos - eye
		dir:Normalize()
		local ang = math.deg(math.acos(math.Clamp(forward:Dot(dir), -1, 1)))
		if ang <= maxFov and (not bestAng or ang < bestAng) then
			local tr = util.TraceLine({ start = eye, endpos = pos, filter = me, mask = MASK_SHOT })
			if tr.Entity == ent or tr.Fraction >= 1 then best, bestPos, bestAng = ent, pos, ang end
		end
	end
	return best, bestPos
end

hook.Add("CreateMove", "HT_AimAssist", function(cmd)
	local me = LP()
	aimTarget = nil
	if not me or not HT.IsOn(me, "aim") then return end

	local eye = me:EyePos()
	local view = cmd:GetViewAngles()
	local target, pos = FindAimTarget(me, eye, view:Forward(), Get(me, "HT_AimFov"))
	aimTarget = target
	if not target then return end
	if Get(me, "HT_AimOnFire") and not (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then return end

	local strength = Get(me, "HT_AimStrength")
	if strength <= 0 then return end
	local want = (pos - eye):Angle()
	local f = strength >= 1 and 1 or 1 - (1 - strength) ^ (FrameTime() * 30)

	local new = Angle(
		view.p + math.AngleDifference(want.p, view.p) * f,
		view.y + math.AngleDifference(want.y, view.y) * f,
		0
	)
	new.p = math.Clamp(math.NormalizeAngle(new.p), -89, 89)
	new.y = math.NormalizeAngle(new.y)
	cmd:SetViewAngles(new)
end)

------------------------------------------------------------------------
-- Radar outline + chaser thermal
------------------------------------------------------------------------

local function ChaserTargets(me)
	if not HT.IsActive(me, "chaser") then return {} end
	local radiusSqr = me:GetNWFloat("HT_ChaserRadius", 0) ^ 2
	local origin, list = me:GetPos(), {}
	for _, ply in ipairs(SenseTargets()) do
		if origin:DistToSqr(ply:GetPos()) <= radiusSqr then list[#list + 1] = ply end
	end
	return list
end

hook.Add("PreDrawHalos", "HT_Halos", function()
	local me = LP()
	if me and HT.IsOn(me, "radar") then
		halo.Add(SenseTargets(), Color(255, 40, 40), 2, 2, 1, true, true)
	end
end)

local thermalMat = Material("models/debug/debugwhite")

hook.Add("PostDrawTranslucentRenderables", "HT_Thermal", function(depth, sky)
	if depth or sky then return end
	local me = LP()
	if not me or not HT.IsHunter(me) then return end

	local targets = ChaserTargets(me)
	if #targets == 0 then return end
	local alpha = math.Clamp(HT.ActiveLeft(me, "chaser"), 0, 1)

	cam.IgnoreZ(true)
	render.SuppressEngineLighting(true)
	render.MaterialOverride(thermalMat)
	render.SetBlend(0.9 * alpha)
	for _, ply in ipairs(targets) do
		render.SetColorModulation(1, 0.45 + math.sin(CurTime() * 6) * 0.1, 0.1)
		ply:DrawModel()
	end
	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
	render.MaterialOverride(nil)
	render.SuppressEngineLighting(false)
	cam.IgnoreZ(false)
end)

------------------------------------------------------------------------
-- Roar (victim side), flashlight blind (hunter side)
------------------------------------------------------------------------

net.Receive("HT_Roared", function()
	util.ScreenShake(LocalPlayer():GetPos(), 12, 8, net.ReadFloat(), 200)
end)

hook.Add("RenderScreenspaceEffects", "HT_RoarTint", function()
	local me = LP()
	if not me then return end
	local left = me:GetNWFloat("HT_SlowUntil", 0) - CurTime()
	if left <= 0 then return end
	local k = math.Clamp(left, 0, 1)
	DrawColorModify({
		["$pp_colour_addr"] = 0.12 * k, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -0.05 * k, ["$pp_colour_contrast"] = 1 + 0.2 * k,
		["$pp_colour_colour"] = 1 - 0.5 * k,
		["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
	})
end)

local blindUntil, blindTime = 0, 1

net.Receive("HT_Blind", function()
	blindTime = net.ReadFloat()
	blindUntil = CurTime() + blindTime
	surface.PlaySound("ambient/energy/zap1.wav")
end)

------------------------------------------------------------------------
-- Noise radar pings
------------------------------------------------------------------------

local PING_TIME = 2.5
local pingStyle = {
	{ label = "Running", color = Color(255, 200, 60) },
	{ label = "Jump",    color = Color(120, 200, 255) },
	{ label = "Shot",    color = Color(255, 60, 60) },
}
local pings = {}

net.Receive("HT_Ping", function()
	pings[#pings + 1] = { pos = net.ReadVector(), kind = net.ReadUInt(2), time = CurTime() }
end)

local function DrawPings()
	local now = CurTime()
	for i = #pings, 1, -1 do
		local p = pings[i]
		local age = now - p.time
		if age > PING_TIME then
			table.remove(pings, i)
		else
			local scr = p.pos:ToScreen()
			if scr.visible then
				local style = pingStyle[p.kind] or pingStyle[1]
				local alpha = 255 * (1 - age / PING_TIME)
				local c = ColorAlpha(style.color, alpha)
				surface.DrawCircle(scr.x, scr.y, 6 + age * 25, c)
				surface.DrawCircle(scr.x, scr.y, 4, c)
				draw.SimpleTextOutlined(style.label, "DermaDefault", scr.x, scr.y - 12, c,
					TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0, alpha))
			end
		end
	end
end

------------------------------------------------------------------------
-- Footprints
------------------------------------------------------------------------

local footMat = Material("sprites/light_glow02_add")
local prints = {}

net.Receive("HT_Tracks", function()
	local now = CurTime()
	for _ = 1, net.ReadUInt(8) do
		local pos, yaw, left = net.ReadVector(), net.ReadFloat(), net.ReadBool()
		local side = Angle(0, yaw, 0):Right() * (left and -5 or 5)
		prints[#prints + 1] = { pos = pos + side + Vector(0, 0, 2), yaw = yaw, time = now }
	end
end)

hook.Add("PostDrawTranslucentRenderables", "HT_Tracks", function(depth, sky)
	if depth or sky or #prints == 0 then return end
	local now, life = CurTime(), CV.tracksTime:GetFloat()
	local up = Vector(0, 0, 1)
	render.SetMaterial(footMat)
	for i = #prints, 1, -1 do
		local p = prints[i]
		local age = now - p.time
		if age > life then
			table.remove(prints, i)
		else
			render.DrawQuadEasy(p.pos, up, 10, 16, Color(60, 200, 255, 255 * (1 - age / life)), p.yaw)
		end
	end
end)

------------------------------------------------------------------------
-- Heartbeat (hunter sensor and victim heartbeat)
------------------------------------------------------------------------

local HEART_SOUND = "physics/body/body_medium_impact_soft1.wav"
local heartDist, heartTime, nextBeat = -1, 0, 0

net.Receive("HT_Heart", function()
	heartDist = net.ReadFloat()
	heartTime = CurTime()
end)

hook.Add("Think", "HT_Heartbeat", function()
	local me = LP()
	if not me or not me:Alive() then return end

	local range
	if HT.IsHunter(me) then
		if not HT.IsOn(me, "heart") then return end
		range = CV.heartRange:GetFloat()
	else
		if not CV.victimHeart:GetBool() then return end
		range = CV.victimHeartRange:GetFloat()
	end
	if CurTime() - heartTime > 1 then return end
	if heartDist < 0 or heartDist > range then return end

	local now = CurTime()
	if now < nextBeat then return end

	local closeness = 1 - heartDist / range
	nextBeat = now + Lerp(closeness, 1.4, 0.35)
	local vol = Lerp(closeness, 0.25, 1)
	me:EmitSound(HEART_SOUND, 75, 60, vol, CHAN_STATIC)
	timer.Simple(0.16, function()
		if IsValid(me) then me:EmitSound(HEART_SOUND, 75, 52, vol * 0.8, CHAN_STATIC) end
	end)
end)

------------------------------------------------------------------------
-- HUD
------------------------------------------------------------------------

local ROW_H, ROW_GAP = 26, 4
local cdMax = {}

-- One HUD row: slot number, name, status, key
local function DrawRow(x, y, w, num, name, nameCol, status, statusCol, key, frac, outline)
	draw.RoundedBox(4, x, y, w, ROW_H, C.panel)
	surface.SetDrawColor(outline or C.line)
	surface.DrawOutlinedRect(x, y, w, ROW_H)

	draw.SimpleText(num, "HT_RowBold", x + 13, y + ROW_H / 2, C.faint, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(name, "HT_Row", x + 28, y + ROW_H / 2, nameCol or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	local right = x + w - 6
	if key then
		surface.SetFont("HT_Key")
		local kw = surface.GetTextSize(key) + 10
		draw.RoundedBox(3, right - kw, y + 4, kw, ROW_H - 8, Color(43, 34, 35))
		draw.SimpleText(key, "HT_Key", right - kw / 2, y + ROW_H / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		right = right - kw - 8
	end
	if status then
		draw.SimpleText(status, "HT_Key", right, y + ROW_H / 2, statusCol or C.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
	if frac then
		surface.SetDrawColor(outline or C.muted)
		surface.DrawRect(x + 2, y + ROW_H - 3, (w - 4) * math.Clamp(frac, 0, 1), 2)
	end
end

-- Status text for an ability; returns status, color, progress, outline
local function AbilityStatus(me, def)
	if def.kind == "toggle" then
		if HT.IsOn(me, def.id) then return "ON", C.good end
		return "OFF", C.faint
	end
	if HT.IsActive(me, def.id) then
		return string.format("ACTIVE %.1fs", HT.ActiveLeft(me, def.id)), C.cold, nil, C.cold
	end
	local ready = HT.ReadyIn(me, def.id)
	if ready > 0 then
		cdMax[def.id] = math.max(cdMax[def.id] or 0, ready)
		return string.format("%ds", math.ceil(ready)), C.muted, ready / cdMax[def.id]
	end
	cdMax[def.id] = nil
	return "READY", C.good
end

local function DrawRoundTimer()
	local phase = HT.Phase()
	if phase ~= "prep" and phase ~= "hunt" then return end
	local left = HT.PhaseEnd() - CurTime()
	local x = ScrW() / 2

	draw.SimpleTextOutlined(HT.FormatTime(left), "HT_Timer", x, 12, phase == "prep" and C.warn or C.text,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
	local sub = phase == "prep" and "HIDE! THE HUNT STARTS SOON" or nil
	local y = 80
	if sub then
		draw.SimpleTextOutlined(sub, "HT_Sub", x, y, C.warn, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
		y = y + 22
	end
	local names = GetGlobalString("HT_HunterNames", "")
	if names ~= "" then
		draw.SimpleTextOutlined(string.upper((string.find(names, ",") and "Hunters: " or "Hunter: ") .. names),
			"HT_Sub", x, y, Color(233, 165, 158), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
	end
end

local function DrawHunterHUD(me)
	local w = 300
	local x, y = ScrW() - w - 20, 20
	local lo = HT.Loadout(me)

	for i = 1, HT.SLOTS do
		local id = lo.slots[i]
		local def = id and HT.AbilityByID[id]
		local key = HT.KeyName(HT.Keys["slot" .. i]:GetInt())
		if def then
			local status, col, frac, outline = AbilityStatus(me, def)
			DrawRow(x, y, w, tostring(i), def.name, frac and C.muted or C.text, status, col, key, frac, outline)
		else
			DrawRow(x, y, w, tostring(i), "— empty —", C.faint, nil, nil, key)
		end
		y = y + ROW_H + ROW_GAP
	end

	DrawRow(x, y, w, "≡", "Hunter menu", C.text, nil, nil, HT.KeyName(HT.Keys.menu:GetInt()))
	y = y + ROW_H + ROW_GAP

	-- last used ability: running, then cooling down
	local last = HT.LastUsed and HT.AbilityByID[HT.LastUsed]
	if last and lo.state[last.id] then
		local text, col
		if HT.IsActive(me, last.id) then
			text, col = string.format("%s active  %.1fs", last.name, HT.ActiveLeft(me, last.id)), C.cold
		elseif HT.ReadyIn(me, last.id) > 0 then
			text, col = string.format("%s cooldown  %ds", last.name, math.ceil(HT.ReadyIn(me, last.id))), C.muted
		end
		if text then
			DrawRow(x, y, w, "↻", text, col, nil, nil, nil, nil, col)
			y = y + ROW_H + ROW_GAP
		end
	end

	local passive = {}
	for _, def in ipairs(HT.HunterAbilities) do
		if lo.state[def.id] == "p" then passive[#passive + 1] = def.name end
	end
	local role = me:GetNWString("HT_RoleName", "")
	draw.SimpleTextOutlined(role ~= "" and ("Role: " .. role) or "", "HT_Row", x + w, y + 2, C.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, color_black)
	if #passive > 0 then
		draw.SimpleTextOutlined("Passive: " .. table.concat(passive, ", "), "HT_Row", x + w, y + 20, C.good,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, color_black)
	end
end

local function DrawVictimHUD(me)
	local w = 260
	local rows = {}
	for i = 1, HT.SLOTS do
		local def = HT.SlotAbility(me, i)
		if def then rows[#rows + 1] = { i, def } end
	end
	local extra = {}
	if me:GetNWFloat("HT_BoostUntil", 0) > CurTime() then extra[#extra + 1] = { "ADRENALINE", C.warn } end
	if HT.IsHidden(me) then extra[#extra + 1] = { "HIDDEN", C.good } end

	local x = 20
	local y = ScrH() - 150 - (#rows + #extra) * (ROW_H + ROW_GAP)
	for _, r in ipairs(rows) do
		local status, col, frac, outline = AbilityStatus(me, r[2])
		DrawRow(x, y, w, tostring(r[1]), r[2].name, frac and C.muted or C.text, status, col,
			HT.KeyName(HT.Keys["slot" .. r[1]]:GetInt()), frac, outline)
		y = y + ROW_H + ROW_GAP
	end
	for _, e in ipairs(extra) do
		DrawRow(x, y, w, "★", e[1], e[2], nil, nil, nil, nil, e[2])
		y = y + ROW_H + ROW_GAP
	end
end

local function DrawAimCircle(me)
	local fov = Get(me, "HT_AimFov")
	local radius = math.tan(math.rad(fov)) / math.tan(math.rad(me:GetFOV() / 2)) * ScrH() * 2 / 3
	surface.DrawCircle(ScrW() / 2, ScrH() / 2, radius, IsValid(aimTarget) and Color(80, 255, 80, 160) or Color(255, 255, 255, 60))
	if IsValid(aimTarget) then
		local p = AimPoint(aimTarget):ToScreen()
		if p.visible then
			surface.SetDrawColor(80, 255, 80, 200)
			surface.DrawOutlinedRect(p.x - 5, p.y - 5, 10, 10)
		end
	end
end

-- Hunter is blind during the hiding phase
hook.Add("HUDPaintBackground", "HT_PrepBlind", function()
	local me = LP()
	if not me or not HT.IsHunter(me) or HT.Phase() ~= "prep" then return end
	surface.SetDrawColor(0, 0, 0, 252)
	surface.DrawRect(0, 0, ScrW(), ScrH())
	draw.SimpleText("YOU ARE THE HUNTER", "HT_Big", ScrW() / 2, ScrH() / 2 - 30, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Role: " .. me:GetNWString("HT_RoleName", "?") .. "   ·   The victims are hiding.",
		"HT_Sub", ScrW() / 2, ScrH() / 2 + 14, C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

local UNIT_TO_M = 0.01905

hook.Add("HUDPaint", "HT_HUD", function()
	local me = LP()
	if not me then return end

	DrawRoundTimer()

	if HT.IsHunter(me) then
		if me:Alive() then DrawHunterHUD(me) end
		if HT.IsOn(me, "aim") then DrawAimCircle(me) end
		if HT.IsOn(me, "radar") and Get(me, "HT_ESPNames") then
			for _, ply in ipairs(SenseTargets()) do
				local pos = (ply:GetPos() + Vector(0, 0, 80)):ToScreen()
				if pos.visible then
					local dist = math.Round(me:GetPos():Distance(ply:GetPos()) * UNIT_TO_M)
					draw.SimpleTextOutlined(ply:Nick() .. " [" .. dist .. "m]", "DermaDefault", pos.x, pos.y,
						Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
				end
			end
		end
		DrawPings()
	elseif HT.IsVictim(me) then
		DrawVictimHUD(me)
	end

	-- flashlight blind: white screen, fades out in the second half
	local left = blindUntil - CurTime()
	if left > 0 then
		surface.SetDrawColor(255, 255, 255, math.Clamp(left / blindTime * 2, 0, 1) * 255)
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end
end)
