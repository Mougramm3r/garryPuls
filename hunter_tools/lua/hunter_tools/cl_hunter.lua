-- Hunter Tools: Client (Menü, Keybinds, Aim-Hilfe, Radar, Chaser-Wärmebild)

local CV = HunterTools.CV
local Get = HunterTools.Get

-- Tastenbelegung (nur für dich, wird gespeichert)
local keys = {
	menu   = CreateClientConVar("ht_key_menu", tostring(KEY_F5), true, false, "Taste: Menü"),
	aim    = CreateClientConVar("ht_key_aim", tostring(KEY_PAD_1), true, false, "Taste: Aim-Hilfe an/aus"),
	esp    = CreateClientConVar("ht_key_esp", tostring(KEY_PAD_2), true, false, "Taste: Radar an/aus"),
	chaser = CreateClientConVar("ht_key_chaser", tostring(KEY_PAD_3), true, false, "Taste: Chaser-Puls"),
}

local function Notify(msg)
	chat.AddText(Color(255, 90, 40), "[Hunter] ", color_white, msg)
end

local function LP()
	local ply = LocalPlayer()
	return IsValid(ply) and ply or nil
end

local function IsHunter()
	local ply = LP()
	return ply ~= nil and HunterTools.IsHunter(ply)
end

-- Alle sichtbaren (übertragenen) Spieler-Ziele
local function Targets()
	local me, list = LP(), {}
	if not me then return list end
	for _, ply in ipairs(player.GetAll()) do
		if HunterTools.IsTarget(me, ply) and not ply:IsDormant() then
			list[#list + 1] = ply
		end
	end
	return list
end

-- NPCs / Nextbots (optional für die Aim-Hilfe, praktisch auch zum Testen)
local npcCache, npcCacheTime = {}, 0
local function NPCTargets()
	if CurTime() - npcCacheTime > 0.5 then
		npcCacheTime = CurTime()
		npcCache = {}
		for _, ent in ipairs(ents.GetAll()) do
			if (ent:IsNPC() or ent:IsNextBot()) and ent:Health() > 0 then
				npcCache[#npcCache + 1] = ent
			end
		end
	end
	local list = {}
	for _, ent in ipairs(npcCache) do
		if IsValid(ent) and not ent:IsDormant() and ent:Health() > 0 then list[#list + 1] = ent end
	end
	return list
end

------------------------------------------------------------------------
-- Einstellungen an den Server senden
------------------------------------------------------------------------

local function SendSetting(target, key, value, instant)
	if isbool(value) then value = value and 1 or 0 end
	local function send()
		if not IsValid(target) then return end
		net.Start("HT_Set")
		net.WriteEntity(target)
		net.WriteString(key)
		net.WriteFloat(value)
		net.SendToServer()
	end
	if instant then send() return end
	-- Kurz warten, damit beim Ziehen am Slider nicht jede Zwischenstufe gesendet wird.
	timer.Create("HT_Set_" .. target:EntIndex() .. key, 0.2, 1, send)
end

-- Eigene Einstellungen merken und beim nächsten Joinen wiederherstellen
local restored = false

hook.Add("InitPostEntity", "HT_Restore", function()
	timer.Simple(2, function()
		local me = LP()
		if not me then return end
		for _, s in ipairs(HunterTools.Settings) do
			local saved = cookie.GetNumber("ht_" .. s.key)
			if saved and s.key ~= "HT_AimOn" and s.key ~= "HT_ESP" then
				SendSetting(me, s.key, saved, true)
			end
		end
		restored = true
	end)
end)

timer.Create("HT_Save", 3, 0, function()
	local me = LP()
	if not me or not restored then return end
	for _, s in ipairs(HunterTools.Settings) do
		local v = Get(me, s.key)
		cookie.Set("ht_" .. s.key, tostring(isbool(v) and (v and 1 or 0) or v))
	end
end)

------------------------------------------------------------------------
-- Aktionen
------------------------------------------------------------------------

local function ToggleSetting(key, allowed, name)
	local me = LP()
	if not me then return end
	if not allowed:GetBool() then Notify(name .. " ist auf diesem Server deaktiviert.") return end
	local on = not Get(me, key)
	SendSetting(me, key, on, true)
	surface.PlaySound("buttons/blip1.wav")
	Notify(name .. " " .. (on and "AN" or "AUS"))
end

local function TriggerChaser()
	local me = LP()
	if not me then return end
	if not CV.allowChaser:GetBool() then Notify("Chaser-Modus ist auf diesem Server deaktiviert.") return end

	local wait = me:GetNWFloat("HT_ChaserReady", 0) - CurTime()
	if wait > 0 then
		Notify(string.format("Chaser lädt noch (%.0fs)", wait))
		return
	end

	net.Start("HT_Chaser")
	net.SendToServer()
	surface.PlaySound("ambient/levels/citadel/weapon_disintegrate2.wav")
end

------------------------------------------------------------------------
-- Menü-Bausteine
------------------------------------------------------------------------

local menuFrame, playerFrame
local OpenMenu

local function AddHeader(parent, text)
	local h = parent:Add("DLabel")
	h:Dock(TOP)
	h:DockMargin(0, 10, 0, 4)
	h:SetFont("DermaDefaultBold")
	h:SetText(text)
	h:SetTextColor(Color(255, 120, 60))
end

local function AddInfo(parent, text)
	local l = parent:Add("DLabel")
	l:Dock(TOP)
	l:DockMargin(0, 4, 0, 4)
	l:SetWrap(true)
	l:SetAutoStretchVertical(true)
	l:SetText(text)
	l:SetTextColor(Color(200, 200, 200))
end

local function AddButton(parent, text, onClick)
	local btn = parent:Add("DButton")
	btn:Dock(TOP)
	btn:DockMargin(0, 4, 0, 4)
	btn:SetTall(28)
	btn:SetText(text)
	btn.DoClick = onClick
	return btn
end

local function AddCheck(parent, label, value, onChange)
	local c = parent:Add("DCheckBoxLabel")
	c:Dock(TOP)
	c:DockMargin(0, 2, 0, 6)
	c:SetText(label)
	c:SetTextColor(color_white)
	c:SetValue(value)
	c.OnChange = function(_, v) onChange(v) end
	return c
end

local function AddSlider(parent, label, min, max, decimals, value, onChange)
	local s = parent:Add("DNumSlider")
	s:Dock(TOP)
	s:DockMargin(0, 0, 0, 4)
	s:SetText(label)
	s:SetMinMax(min, max)
	s:SetDecimals(decimals)
	s:SetValue(value)
	s.Label:SetTextColor(color_white)
	s.OnValueChanged = function(_, v) onChange(v) end
	return s
end

-- Jäger-Einstellung von "target" (du selbst oder, als Admin, ein anderer Spieler)
local function SettingCheck(parent, label, target, key)
	return AddCheck(parent, label, Get(target, key), function(v) SendSetting(target, key, v) end)
end

local function SettingSlider(parent, label, target, key, decimals)
	local s = HunterTools.SettingByKey[key]
	return AddSlider(parent, label, s.min, math.max(s.min, s.max()), decimals, Get(target, key),
		function(v) SendSetting(target, key, v) end)
end

local function AddBinder(parent, label, cvar)
	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 4)
	row:SetTall(26)
	row:SetPaintBackground(false)

	local lbl = row:Add("DLabel")
	lbl:Dock(LEFT)
	lbl:SetWide(170)
	lbl:SetText(label)
	lbl:SetTextColor(color_white)

	local binder = row:Add("DBinder")
	binder:Dock(FILL)
	binder:SetValue(cvar:GetInt())
	binder.OnChange = function(_, key)
		RunConsoleCommand(cvar:GetName(), tostring(key))
	end
end

local function NewScroll(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:GetCanvas():DockPadding(8, 0, 8, 8)
	return scroll
end

local function StyleFrame(f)
	f.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 24, 240))
		draw.RoundedBoxEx(6, 0, 0, w, 24, Color(140, 30, 20), true, true, false, false)
	end
end

------------------------------------------------------------------------
-- Menü-Inhalte
------------------------------------------------------------------------

-- Fähigkeiten eines Jägers (für dich selbst oder für einen anderen Spieler)
local function BuildAbilities(parent, target)
	AddHeader(parent, "Aim-Hilfe")
	SettingCheck(parent, "Aim-Hilfe aktiv", target, "HT_AimOn")
	SettingCheck(parent, "Nur beim Schießen / Zielen", target, "HT_AimOnFire")
	SettingCheck(parent, "Auch auf NPCs / Nextbots", target, "HT_AimNPC")
	SettingSlider(parent, "Stärke", target, "HT_AimStrength", 2)
	SettingSlider(parent, "Winkel (Grad)", target, "HT_AimFov", 0)
	if not CV.allowAim:GetBool() then AddInfo(parent, "Aim-Hilfe ist im Tab \"Server\" gerade verboten.") end

	AddHeader(parent, "Radar (alle durch Wände)")
	SettingCheck(parent, "Radar aktiv", target, "HT_ESP")
	SettingCheck(parent, "Namen und Entfernung anzeigen", target, "HT_ESPNames")
	if not CV.allowESP:GetBool() then AddInfo(parent, "Radar ist im Tab \"Server\" gerade verboten.") end

	AddHeader(parent, "Chaser-Modus (Wärmebild-Puls)")
	SettingSlider(parent, "Radius (Units)", target, "HT_ChaserCfgRadius", 0)
	SettingSlider(parent, "Dauer (Sekunden)", target, "HT_ChaserCfgTime", 1)
	if not CV.allowChaser:GetBool() then AddInfo(parent, "Chaser-Modus ist im Tab \"Server\" gerade verboten.") end
end

local function SetHunterOnServer(ply, state)
	net.Start("HT_AdminSetHunter")
	net.WriteEntity(ply)
	net.WriteBool(state)
	net.SendToServer()
end

local function ReopenMenu(tab)
	timer.Simple(0.3, function()
		if IsValid(menuFrame) then menuFrame:Remove() end
		menuFrame = nil
		OpenMenu(tab)
	end)
end

local function BuildHunterTab(tab)
	local me = LP()
	if not IsHunter() then
		AddHeader(tab, "Du bist gerade nicht der Jäger")
		if HunterTools.IsManager(me) then
			AddButton(tab, "Mich zum Jäger machen", function()
				SetHunterOnServer(me, true)
				ReopenMenu("Jäger")
			end)
		else
			AddInfo(tab, "Der Host kann dich im Menü zum Jäger machen.")
		end
	else
		AddButton(tab, "Chaser-Puls jetzt auslösen", TriggerChaser)
	end

	BuildAbilities(tab, me)

	AddHeader(tab, "Tasten (anklicken, dann neue Taste drücken)")
	AddBinder(tab, "Menü öffnen", keys.menu)
	AddBinder(tab, "Aim-Hilfe an/aus", keys.aim)
	AddBinder(tab, "Radar an/aus", keys.esp)
	AddBinder(tab, "Chaser-Puls", keys.chaser)
end

-- Zahnrad: Jäger-Tab eines anderen Spielers
local function OpenPlayerSettings(ply)
	if IsValid(playerFrame) then playerFrame:Remove() end
	if not IsValid(ply) then return end

	local f = vgui.Create("DFrame")
	f:SetTitle("Jäger-Einstellungen: " .. ply:Nick())
	f:SetSize(440, 520)
	f:Center()
	f:MakePopup()
	StyleFrame(f)
	playerFrame = f

	local scroll = NewScroll(f)
	scroll:Dock(FILL)

	if not HunterTools.IsHunter(ply) then
		AddInfo(scroll, ply:Nick() .. " ist gerade kein Jäger. Die Einstellungen gelten, sobald er Jäger ist.")
	end
	BuildAbilities(scroll, ply)
end

local function BuildPlayersTab(tab)
	AddHeader(tab, CV.multiHunter:GetBool() and "Wer ist Jäger? (mehrere möglich)" or "Wer ist Jäger? (nur einer)")

	for _, ply in ipairs(player.GetAll()) do
		local row = tab:Add("DPanel")
		row:Dock(TOP)
		row:DockMargin(0, 2, 0, 4)
		row:SetTall(24)
		row:SetPaintBackground(false)

		local gear = row:Add("DImageButton")
		gear:Dock(RIGHT)
		gear:DockMargin(4, 4, 4, 4)
		gear:SetWide(16)
		gear:SetImage("icon16/cog.png")
		gear:SetTooltip("Jäger-Einstellungen von " .. ply:Nick())
		gear.DoClick = function() OpenPlayerSettings(ply) end

		local c = row:Add("DCheckBoxLabel")
		c:Dock(FILL)
		c:SetText(ply:Nick() .. (ply == LP() and "  (du)" or ""))
		c:SetTextColor(color_white)
		c:SetValue(HunterTools.IsHunter(ply))
		c.OnChange = function(_, v)
			if not IsValid(ply) then return end
			SetHunterOnServer(ply, v)
			ReopenMenu("Spieler")
		end
	end
end

local function SetServerCVar(cvar, value)
	timer.Create("HT_SV_" .. cvar:GetName(), 0.25, 1, function()
		net.Start("HT_AdminSetCVar")
		net.WriteString(cvar:GetName())
		net.WriteFloat(value)
		net.SendToServer()
	end)
end

local function ServerCheck(parent, label, cvar)
	return AddCheck(parent, label, cvar:GetBool(), function(v) SetServerCVar(cvar, v and 1 or 0) end)
end

local function ServerSlider(parent, label, cvar, decimals)
	return AddSlider(parent, label, cvar:GetMin() or 0, cvar:GetMax() or 100, decimals, cvar:GetFloat(),
		function(v) SetServerCVar(cvar, v) end)
end

local function BuildServerTab(tab)
	AddInfo(tab, "Diese Grenzen gelten für alle Jäger.")

	AddHeader(tab, "Jäger")
	local multi = ServerCheck(tab, "Mehrere Jäger gleichzeitig erlauben", CV.multiHunter)
	multi.OnChange = function(_, v)
		SetServerCVar(CV.multiHunter, v and 1 or 0)
		ReopenMenu("Server")
	end
	ServerCheck(tab, "Admins automatisch Jäger", CV.adminsAreHunters)

	AddHeader(tab, "Fähigkeiten erlauben")
	ServerCheck(tab, "Aim-Hilfe erlauben", CV.allowAim)
	ServerCheck(tab, "Radar erlauben", CV.allowESP)
	ServerCheck(tab, "Chaser-Modus erlauben", CV.allowChaser)

	AddHeader(tab, "Grenzen")
	ServerSlider(tab, "Max. Aim-Stärke", CV.aimMaxStrength, 2)
	ServerSlider(tab, "Max. Aim-Winkel", CV.aimMaxFov, 0)
	ServerSlider(tab, "Max. Chaser-Radius", CV.chaserMaxRadius, 0)
	ServerSlider(tab, "Max. Chaser-Dauer", CV.chaserMaxTime, 1)
	ServerSlider(tab, "Chaser-Abklingzeit", CV.chaserCooldown, 0)
end

function OpenMenu(activeTab)
	if IsValid(menuFrame) then menuFrame:Close() return end
	local manager = HunterTools.IsManager(LP())
	if not IsHunter() and not manager then Notify("Du bist nicht der Jäger.") return end

	local f = vgui.Create("DFrame")
	f:SetTitle("Hunter Tools")
	f:SetSize(460, 600)
	f:Center()
	f:MakePopup()
	StyleFrame(f)
	menuFrame = f

	local sheet = f:Add("DPropertySheet")
	sheet:Dock(FILL)

	local function Tab(name, icon, build)
		local scroll = NewScroll(sheet)
		build(scroll)
		sheet:AddSheet(name, scroll, icon)
	end

	Tab("Jäger", "icon16/eye.png", BuildHunterTab)
	if manager then
		Tab("Spieler", "icon16/group.png", BuildPlayersTab)
		Tab("Server", "icon16/cog.png", BuildServerTab)
	end
	if isstring(activeTab) then sheet:SwitchToName(activeTab) end
end

------------------------------------------------------------------------
-- Keybinds
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

	-- Immer alle Tasten abfragen, damit beim Freigeben nichts nachträglich auslöst.
	local pMenu, pAim, pESP, pChaser =
		JustPressed(keys.menu), JustPressed(keys.aim), JustPressed(keys.esp), JustPressed(keys.chaser)

	if input.IsKeyTrapping() or gui.IsGameUIVisible() or gui.IsConsoleVisible() or me:IsTyping() then return end

	if pMenu and (HunterTools.IsHunter(me) or HunterTools.IsManager(me)) then OpenMenu() end
	if IsValid(menuFrame) or IsValid(playerFrame) or not HunterTools.IsHunter(me) then return end

	if pAim then ToggleSetting("HT_AimOn", CV.allowAim, "Aim-Hilfe") end
	if pESP then ToggleSetting("HT_ESP", CV.allowESP, "Radar") end
	if pChaser then TriggerChaser() end
end)

------------------------------------------------------------------------
-- Aim-Hilfe: zieht das Fadenkreuz zum nächsten sichtbaren Ziel im Winkel
------------------------------------------------------------------------

local aimTarget -- für die Anzeige im HUD

local function AimActive(me)
	return me:Alive() and HunterTools.IsHunter(me) and CV.allowAim:GetBool() and Get(me, "HT_AimOn")
end

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
			if tr.Entity == ent or tr.Fraction >= 1 then
				best, bestPos, bestAng = ent, pos, ang
			end
		end
	end
	return best, bestPos
end

hook.Add("CreateMove", "HT_AimAssist", function(cmd)
	local me = LP()
	aimTarget = nil
	if not me or not AimActive(me) then return end

	local eye = me:EyePos()
	local view = cmd:GetViewAngles()
	local target, pos = FindAimTarget(me, eye, view:Forward(), Get(me, "HT_AimFov"))
	aimTarget = target
	if not target then return end

	if Get(me, "HT_AimOnFire") and not (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then return end

	local want = (pos - eye):Angle()
	local strength = Get(me, "HT_AimStrength")
	if strength <= 0 then return end

	-- Bildraten-unabhängiges Nachziehen (Stärke 1 = sofort auf dem Ziel)
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
-- Radar (Umriss durch Wände) + Chaser (Wärmebild im Radius)
------------------------------------------------------------------------

local function ESPOn(me)
	return Get(me, "HT_ESP") and CV.allowESP:GetBool()
end

local function ChaserTargets(me)
	if not HunterTools.ChaserActive(me) or not CV.allowChaser:GetBool() then return {} end
	local radiusSqr = me:GetNWFloat("HT_ChaserRadius", 0) ^ 2
	local origin, list = me:GetPos(), {}
	for _, ply in ipairs(Targets()) do
		if origin:DistToSqr(ply:GetPos()) <= radiusSqr then list[#list + 1] = ply end
	end
	return list
end

hook.Add("PreDrawHalos", "HT_Halos", function()
	local me = LP()
	if not me or not HunterTools.IsHunter(me) then return end
	if ESPOn(me) then
		halo.Add(Targets(), Color(255, 40, 40), 2, 2, 1, true, true)
	end
end)

local thermalMat = Material("models/debug/debugwhite")

hook.Add("PostDrawTranslucentRenderables", "HT_Thermal", function(depth, sky)
	if depth or sky then return end
	local me = LP()
	if not me or not HunterTools.IsHunter(me) then return end

	local targets = ChaserTargets(me)
	if #targets == 0 then return end

	-- In der letzten Sekunde ausblenden
	local left = me:GetNWFloat("HT_ChaserUntil", 0) - CurTime()
	local alpha = math.Clamp(left, 0, 1)

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
-- HUD
------------------------------------------------------------------------

local UNIT_TO_M = 0.01905

local function DrawAimCircle(me)
	-- Kreis zeigt den Aim-Hilfe-Winkel; grün, sobald ein Ziel erfasst ist.
	local fov = Get(me, "HT_AimFov")
	local viewFov = me:GetFOV()
	local radius = math.tan(math.rad(fov)) / math.tan(math.rad(viewFov / 2)) * ScrH() * 2 / 3
	local col = IsValid(aimTarget) and Color(80, 255, 80, 160) or Color(255, 255, 255, 60)
	surface.DrawCircle(ScrW() / 2, ScrH() / 2, radius, col)

	if IsValid(aimTarget) then
		local p = AimPoint(aimTarget):ToScreen()
		if p.visible then
			surface.SetDrawColor(80, 255, 80, 200)
			surface.DrawOutlinedRect(p.x - 5, p.y - 5, 10, 10)
		end
	end
end

hook.Add("HUDPaint", "HT_HUD", function()
	local me = LP()
	if not me or not HunterTools.IsHunter(me) then return end

	local now = CurTime()
	local aimOn = AimActive(me)
	local lines = {
		{ "JÄGER", Color(255, 80, 40) },
		{ "Aim: " .. (aimOn and "AN" or "AUS"), color_white },
		{ "Radar: " .. (ESPOn(me) and "AN" or "AUS"), color_white },
	}
	local until_ = me:GetNWFloat("HT_ChaserUntil", 0)
	local ready = me:GetNWFloat("HT_ChaserReady", 0)
	if until_ > now then
		lines[#lines + 1] = { string.format("Chaser: AKTIV %.1fs", until_ - now), Color(255, 140, 40) }
	elseif ready > now then
		lines[#lines + 1] = { string.format("Chaser: lädt %.0fs", ready - now), Color(160, 160, 160) }
	else
		lines[#lines + 1] = { "Chaser: bereit", Color(120, 255, 120) }
	end

	for i, l in ipairs(lines) do
		draw.SimpleTextOutlined(l[1], "DermaDefaultBold", 20, 20 + (i - 1) * 16, l[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
	end

	if aimOn then DrawAimCircle(me) end

	if ESPOn(me) and Get(me, "HT_ESPNames") then
		for _, ply in ipairs(Targets()) do
			local pos = (ply:GetPos() + Vector(0, 0, 80)):ToScreen()
			if pos.visible then
				local dist = math.Round(me:GetPos():Distance(ply:GetPos()) * UNIT_TO_M)
				draw.SimpleTextOutlined(ply:Nick() .. " [" .. dist .. "m]", "DermaDefault", pos.x, pos.y,
					Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
			end
		end
	end
end)
