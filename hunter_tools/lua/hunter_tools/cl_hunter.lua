-- Hunter Tools: Client (Menü, Keybinds, Aim-Hilfe, Radar, Chaser-Wärmebild)

local CV = HunterTools.CV

-- Einstellungen des Jägers (werden gespeichert)
local cl = {
	keyMenu       = CreateClientConVar("ht_key_menu", tostring(KEY_F5), true, false, "Taste: Menü"),
	keyAim        = CreateClientConVar("ht_key_aim", tostring(KEY_PAD_1), true, false, "Taste: Aim-Hilfe an/aus"),
	keyESP        = CreateClientConVar("ht_key_esp", tostring(KEY_PAD_2), true, false, "Taste: Radar an/aus"),
	keyChaser     = CreateClientConVar("ht_key_chaser", tostring(KEY_PAD_3), true, false, "Taste: Chaser-Puls"),

	aimEnabled    = CreateClientConVar("ht_aim_enabled", "0", false, false, "Aim-Hilfe aktiv"),
	aimStrength   = CreateClientConVar("ht_aim_strength", "0.35", true, false, "Aim-Hilfe Stärke", 0, 1),
	aimFov        = CreateClientConVar("ht_aim_fov", "8", true, false, "Aim-Hilfe Winkel", 1, 45),
	aimOnFire     = CreateClientConVar("ht_aim_only_when_firing", "1", true, false, "Aim-Hilfe nur beim Schießen/Zielen"),

	espEnabled    = CreateClientConVar("ht_esp_enabled", "0", false, false, "Radar aktiv"),
	espNames      = CreateClientConVar("ht_esp_names", "1", true, false, "Radar: Namen und Entfernung anzeigen"),

	chaserRadius  = CreateClientConVar("ht_chaser_radius", "1500", true, false, "Chaser-Radius in Units", 100, 20000),
	chaserTime    = CreateClientConVar("ht_chaser_duration", "5", true, false, "Chaser-Dauer in Sekunden", 1, 60),
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

-- Alle sichtbaren (übertragenen) Ziele
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

------------------------------------------------------------------------
-- Aktionen
------------------------------------------------------------------------

cvars.AddChangeCallback("ht_esp_enabled", function(_, _, new)
	net.Start("HT_SetESP")
	net.WriteBool(new == "1")
	net.SendToServer()
end, "HT_ESP")

local function ToggleAim()
	if not CV.allowAim:GetBool() then Notify("Aim-Hilfe ist auf diesem Server deaktiviert.") return end
	local on = not cl.aimEnabled:GetBool()
	cl.aimEnabled:SetBool(on)
	surface.PlaySound("buttons/blip1.wav")
	Notify("Aim-Hilfe " .. (on and "AN" or "AUS"))
end

local function ToggleESP()
	if not CV.allowESP:GetBool() then Notify("Radar ist auf diesem Server deaktiviert.") return end
	local on = not cl.espEnabled:GetBool()
	cl.espEnabled:SetBool(on)
	surface.PlaySound("buttons/blip1.wav")
	Notify("Radar " .. (on and "AN" or "AUS"))
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
	net.WriteUInt(math.Clamp(cl.chaserRadius:GetInt(), 100, 65535), 16)
	net.WriteFloat(cl.chaserTime:GetFloat())
	net.SendToServer()
	surface.PlaySound("ambient/levels/citadel/weapon_disintegrate2.wav")
end

------------------------------------------------------------------------
-- Menü
------------------------------------------------------------------------

local menuFrame
local OpenMenu

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

local function AddSlider(parent, label, cvar, min, max, decimals)
	local s = parent:Add("DNumSlider")
	s:Dock(TOP)
	s:DockMargin(0, 0, 0, 4)
	s:SetText(label)
	s:SetMinMax(min, max)
	s:SetDecimals(decimals or 0)
	s:SetConVar(cvar:GetName())
	s.Label:SetTextColor(color_white)
	return s
end

local function AddCheck(parent, label, cvar)
	local c = parent:Add("DCheckBoxLabel")
	c:Dock(TOP)
	c:DockMargin(0, 2, 0, 6)
	c:SetText(label)
	c:SetConVar(cvar:GetName())
	c:SetTextColor(color_white)
	return c
end

local function AddHeader(parent, text)
	local h = parent:Add("DLabel")
	h:Dock(TOP)
	h:DockMargin(0, 10, 0, 4)
	h:SetFont("DermaDefaultBold")
	h:SetText(text)
	h:SetTextColor(Color(255, 120, 60))
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

local function AddInfo(parent, text)
	local l = parent:Add("DLabel")
	l:Dock(TOP)
	l:DockMargin(0, 4, 0, 4)
	l:SetWrap(true)
	l:SetAutoStretchVertical(true)
	l:SetText(text)
	l:SetTextColor(Color(200, 200, 200))
end

local function SetHunterOnServer(ply, state)
	net.Start("HT_AdminSetHunter")
	net.WriteEntity(ply)
	net.WriteBool(state)
	net.SendToServer()
end

local function SetServerCVar(cvar, value)
	-- Kurz warten, damit beim Ziehen am Slider nicht jede Zwischenstufe gesendet wird.
	timer.Create("HT_SV_" .. cvar:GetName(), 0.25, 1, function()
		net.Start("HT_AdminSetCVar")
		net.WriteString(cvar:GetName())
		net.WriteFloat(value)
		net.SendToServer()
	end)
end

local function AddServerSlider(parent, label, cvar, decimals)
	local s = parent:Add("DNumSlider")
	s:Dock(TOP)
	s:DockMargin(0, 0, 0, 4)
	s:SetText(label)
	s:SetMinMax(cvar:GetMin() or 0, cvar:GetMax() or 100)
	s:SetDecimals(decimals or 0)
	s:SetValue(cvar:GetFloat())
	s.Label:SetTextColor(color_white)
	s.OnValueChanged = function(_, v) SetServerCVar(cvar, v) end
end

local function AddServerCheck(parent, label, cvar)
	local c = parent:Add("DCheckBoxLabel")
	c:Dock(TOP)
	c:DockMargin(0, 2, 0, 6)
	c:SetText(label)
	c:SetTextColor(color_white)
	c:SetValue(cvar:GetBool())
	c.OnChange = function(_, v) SetServerCVar(cvar, v and 1 or 0) end
end

local function NewTab(sheet, name, icon)
	local scroll = vgui.Create("DScrollPanel", sheet)
	scroll:GetCanvas():DockPadding(8, 0, 8, 8)
	sheet:AddSheet(name, scroll, icon)
	return scroll
end

local function BuildHunterTab(tab)
	if not IsHunter() then
		AddHeader(tab, "Du bist gerade nicht der Jäger")
		if HunterTools.IsManager(LP()) then
			AddButton(tab, "Mich zum Jäger machen", function()
				SetHunterOnServer(LP(), true)
				timer.Simple(0.3, function()
					if IsValid(menuFrame) then menuFrame:Remove() menuFrame = nil OpenMenu() end
				end)
			end)
			AddInfo(tab, "Oder im Tab \"Spieler\" jemand anderen auswählen.")
		else
			AddInfo(tab, "Der Host kann dich im Menü zum Jäger machen.")
		end
		return
	end

	AddHeader(tab, "Aim-Hilfe")
	AddCheck(tab, "Aim-Hilfe aktiv", cl.aimEnabled)
	AddCheck(tab, "Nur beim Schießen / Zielen", cl.aimOnFire)
	AddSlider(tab, "Stärke", cl.aimStrength, 0, CV.aimMaxStrength:GetFloat(), 2)
	AddSlider(tab, "Winkel (Grad)", cl.aimFov, 1, CV.aimMaxFov:GetFloat(), 0)

	AddHeader(tab, "Radar (alle durch Wände)")
	AddCheck(tab, "Radar aktiv", cl.espEnabled)
	AddCheck(tab, "Namen und Entfernung anzeigen", cl.espNames)

	AddHeader(tab, "Chaser-Modus (Wärmebild-Puls)")
	AddSlider(tab, "Radius (Units)", cl.chaserRadius, 100, CV.chaserMaxRadius:GetFloat(), 0)
	AddSlider(tab, "Dauer (Sekunden)", cl.chaserTime, 1, CV.chaserMaxTime:GetFloat(), 1)
	AddButton(tab, "Chaser-Puls jetzt auslösen", TriggerChaser)

	AddHeader(tab, "Tasten (anklicken, dann neue Taste drücken)")
	AddBinder(tab, "Menü öffnen", cl.keyMenu)
	AddBinder(tab, "Aim-Hilfe an/aus", cl.keyAim)
	AddBinder(tab, "Radar an/aus", cl.keyESP)
	AddBinder(tab, "Chaser-Puls", cl.keyChaser)
end

local function BuildPlayersTab(tab)
	AddHeader(tab, "Wer ist Jäger? (Haken setzen)")
	for _, ply in ipairs(player.GetAll()) do
		local c = tab:Add("DCheckBoxLabel")
		c:Dock(TOP)
		c:DockMargin(0, 2, 0, 6)
		c:SetText(ply:Nick() .. (ply == LP() and "  (du)" or ""))
		c:SetTextColor(color_white)
		c:SetValue(HunterTools.IsHunter(ply))
		c.OnChange = function(_, v)
			if IsValid(ply) then SetHunterOnServer(ply, v) end
		end
	end
end

local function BuildServerTab(tab)
	AddInfo(tab, "Diese Grenzen gelten für alle Jäger. Der Jäger kann im Tab \"Jäger\" nur innerhalb davon einstellen.")
	AddHeader(tab, "Fähigkeiten erlauben")
	AddServerCheck(tab, "Aim-Hilfe erlauben", CV.allowAim)
	AddServerCheck(tab, "Radar erlauben", CV.allowESP)
	AddServerCheck(tab, "Chaser-Modus erlauben", CV.allowChaser)
	AddServerCheck(tab, "Admins automatisch Jäger", CV.adminsAreHunters)

	AddHeader(tab, "Grenzen")
	AddServerSlider(tab, "Max. Aim-Stärke", CV.aimMaxStrength, 2)
	AddServerSlider(tab, "Max. Aim-Winkel", CV.aimMaxFov, 0)
	AddServerSlider(tab, "Max. Chaser-Radius", CV.chaserMaxRadius, 0)
	AddServerSlider(tab, "Max. Chaser-Dauer", CV.chaserMaxTime, 1)
	AddServerSlider(tab, "Chaser-Abklingzeit", CV.chaserCooldown, 0)
end

function OpenMenu()
	if IsValid(menuFrame) then menuFrame:Close() return end
	local manager = HunterTools.IsManager(LP())
	if not IsHunter() and not manager then Notify("Du bist nicht der Jäger.") return end

	local f = vgui.Create("DFrame")
	f:SetTitle("Hunter Tools")
	f:SetSize(460, 580)
	f:Center()
	f:MakePopup()
	f.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 24, 240))
		draw.RoundedBoxEx(6, 0, 0, w, 24, Color(140, 30, 20), true, true, false, false)
	end
	menuFrame = f

	local sheet = f:Add("DPropertySheet")
	sheet:Dock(FILL)

	BuildHunterTab(NewTab(sheet, "Jäger", "icon16/eye.png"))
	if manager then
		BuildPlayersTab(NewTab(sheet, "Spieler", "icon16/group.png"))
		BuildServerTab(NewTab(sheet, "Server", "icon16/cog.png"))
	end
end

concommand.Add("ht_menu", OpenMenu)
concommand.Add("ht_toggle_aim", function() if IsHunter() then ToggleAim() end end)
concommand.Add("ht_toggle_esp", function() if IsHunter() then ToggleESP() end end)
concommand.Add("ht_chaser", function() if IsHunter() then TriggerChaser() end end)

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
		JustPressed(cl.keyMenu), JustPressed(cl.keyAim), JustPressed(cl.keyESP), JustPressed(cl.keyChaser)

	if input.IsKeyTrapping() or gui.IsGameUIVisible() or gui.IsConsoleVisible() or me:IsTyping() then return end

	if pMenu and (HunterTools.IsHunter(me) or HunterTools.IsManager(me)) then OpenMenu() end
	if IsValid(menuFrame) or not HunterTools.IsHunter(me) then return end

	if pAim then ToggleAim() end
	if pESP then ToggleESP() end
	if pChaser then TriggerChaser() end
end)

------------------------------------------------------------------------
-- Aim-Hilfe: zieht das Fadenkreuz sanft zum nächsten sichtbaren Ziel
------------------------------------------------------------------------

local function AimPoint(ply)
	local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
	if bone then
		local pos = ply:GetBonePosition(bone)
		if pos then return pos end
	end
	return ply:WorldSpaceCenter()
end

hook.Add("CreateMove", "HT_AimAssist", function(cmd)
	local me = LP()
	if not me or not me:Alive() or not HunterTools.IsHunter(me) then return end
	if not cl.aimEnabled:GetBool() or not CV.allowAim:GetBool() then return end
	if cl.aimOnFire:GetBool() and not (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then return end

	local eye = me:EyePos()
	local view = cmd:GetViewAngles()
	local forward = view:Forward()
	local maxFov = math.min(cl.aimFov:GetFloat(), CV.aimMaxFov:GetFloat())

	local best, bestAng
	for _, ply in ipairs(Targets()) do
		local pos = AimPoint(ply)
		local dir = pos - eye
		dir:Normalize()
		local ang = math.deg(math.acos(math.Clamp(forward:Dot(dir), -1, 1)))
		if ang <= maxFov and (not bestAng or ang < bestAng) then
			local tr = util.TraceLine({ start = eye, endpos = pos, filter = me, mask = MASK_SHOT })
			if tr.Entity == ply or tr.Fraction >= 1 then
				best, bestAng = pos, ang
			end
		end
	end
	if not best then return end

	local want = (best - eye):Angle()
	local strength = math.Clamp(cl.aimStrength:GetFloat(), 0, CV.aimMaxStrength:GetFloat())
	-- Bildraten-unabhängiges Nachziehen
	local f = 1 - (1 - strength) ^ (FrameTime() * 20)

	local new = Angle(
		view.p + math.AngleDifference(want.p, view.p) * f,
		view.y + math.AngleDifference(want.y, view.y) * f,
		view.r
	)
	new.p = math.Clamp(math.NormalizeAngle(new.p), -89, 89)
	new.y = math.NormalizeAngle(new.y)
	cmd:SetViewAngles(new)
end)

------------------------------------------------------------------------
-- Radar (Umriss durch Wände) + Chaser (Wärmebild im Radius)
------------------------------------------------------------------------

local function ESPOn(me)
	return me:GetNWBool("HT_ESP", false) and CV.allowESP:GetBool()
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

hook.Add("HUDPaint", "HT_HUD", function()
	local me = LP()
	if not me or not HunterTools.IsHunter(me) then return end

	local now = CurTime()
	local lines = {
		{ "JÄGER", Color(255, 80, 40) },
		{ "Aim: " .. (cl.aimEnabled:GetBool() and CV.allowAim:GetBool() and "AN" or "AUS"), color_white },
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

	if ESPOn(me) and cl.espNames:GetBool() then
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
