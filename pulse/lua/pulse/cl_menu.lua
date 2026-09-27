-- PULSE: menu, sound picker, role choice and round results

local HT = Pulse
local CV = HT.CV
local C = HT.Colors
local Get = HT.Get
local LP = HT.LP

surface.CreateFont("HT_Tab", { font = "Roboto", size = 18, weight = 800 })
surface.CreateFont("HT_Header", { font = "Roboto", size = 20, weight = 800 })
surface.CreateFont("HT_Side", { font = "Roboto", size = 15, weight = 500 })

local menuFrame, playerFrame, soundFrame, roleFrame, endFrame
local state = { tab = "keys", sub = "abilities" }
local editingRole -- role name being edited in the Game tab ("__new" for a new one)

function HT.AnyWindowOpen()
	return IsValid(menuFrame) or IsValid(playerFrame) or IsValid(soundFrame) or IsValid(roleFrame) or IsValid(endFrame)
end

------------------------------------------------------------------------
-- Building blocks
------------------------------------------------------------------------

local function StyleFrame(f)
	f.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(22, 18, 19, 248))
		draw.RoundedBoxEx(6, 0, 0, w, 24, Color(74, 23, 20), true, true, false, false)
	end
end

local function NewFrame(title, w, h)
	local f = vgui.Create("DFrame")
	f:SetTitle(title)
	f:SetSize(math.min(w, ScrW() - 40), math.min(h, ScrH() - 40))
	f:Center()
	f:MakePopup()
	StyleFrame(f)
	return f
end

local function NewScroll(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:GetCanvas():DockPadding(12, 4, 12, 12)
	return scroll
end

local function AddHeader(parent, text)
	local h = parent:Add("DLabel")
	h:Dock(TOP)
	h:DockMargin(0, 12, 0, 6)
	h:SetFont("HT_Header")
	h:SetText(text)
	h:SetTextColor(C.text)
	h:SizeToContentsY(4)
	return h
end

local function AddInfo(parent, text, color)
	local l = parent:Add("DLabel")
	l:Dock(TOP)
	l:DockMargin(0, 2, 0, 6)
	l:SetWrap(true)
	l:SetAutoStretchVertical(true)
	l:SetText(text)
	l:SetTextColor(color or C.muted)
	return l
end

local function AddButton(parent, text, onClick)
	local b = parent:Add("DButton")
	b:Dock(TOP)
	b:DockMargin(0, 4, 0, 4)
	b:SetTall(28)
	b:SetText(text)
	b.DoClick = onClick
	return b
end

local function Row(parent, label, tall)
	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 4)
	row:SetTall(tall or 26)
	row:SetPaintBackground(false)
	local lbl = row:Add("DLabel")
	lbl:Dock(LEFT)
	lbl:SetWide(220)
	lbl:SetText(label)
	lbl:SetTextColor(C.text)
	return row, lbl
end

local function AddCheck(parent, label, value, onChange)
	local c = parent:Add("DCheckBoxLabel")
	c:Dock(TOP)
	c:DockMargin(0, 3, 0, 7)
	c:SetText(label)
	c:SetTextColor(C.text)
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
	s.Label:SetTextColor(C.text)
	s.OnValueChanged = function(_, v) onChange(v) end
	return s
end

-- options = { { "Text", data }, ... }
local function AddCombo(parent, label, options, selected, onSelect)
	local row = Row(parent, label)
	local cb = row:Add("DComboBox")
	cb:Dock(FILL)
	for _, o in ipairs(options) do cb:AddChoice(o[1], o[2], o[2] == selected) end
	cb.OnSelect = function(_, _, _, data) onSelect(data) end
	return cb
end

local function AddBinder(parent, label, cvar)
	local row = Row(parent, label, 28)
	local binder = row:Add("DBinder")
	binder:Dock(FILL)
	binder:SetValue(cvar:GetInt())
	binder.OnChange = function(_, key) RunConsoleCommand(cvar:GetName(), tostring(key)) end
end

-- Sections: { { "Title", function(parent) ... end }, ... } with a jump list on the left
local function BuildSections(body, sections)
	local side = body:Add("DScrollPanel")
	side:Dock(LEFT)
	side:SetWide(170)
	side.Paint = function(_, w, h)
		surface.SetDrawColor(C.line)
		surface.DrawLine(w - 1, 0, w - 1, h)
	end
	side:GetCanvas():DockPadding(8, 10, 8, 8)

	local cap = side:Add("DLabel")
	cap:Dock(TOP)
	cap:SetText("SECTIONS")
	cap:SetTextColor(C.faint)
	cap:DockMargin(6, 0, 0, 6)

	local content = NewScroll(body)
	content:Dock(FILL)

	for _, sec in ipairs(sections) do
		local header = AddHeader(content, sec[1])
		sec[2](content)

		local link = side:Add("DButton")
		link:Dock(TOP)
		link:SetTall(26)
		link:SetText("")
		link.Paint = function(self, w, h)
			if self:IsHovered() then draw.RoundedBox(4, 0, 0, w, h, Color(43, 34, 35)) end
			draw.SimpleText(sec[1], "HT_Side", 8, h / 2, self:IsHovered() and C.text or C.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		link.DoClick = function() content:ScrollToChild(header) end
	end
	return content
end

------------------------------------------------------------------------
-- Helpers for roles and loadouts
------------------------------------------------------------------------

local function LoadoutSummary(str)
	local lo = HT.ParseLoadout(str)
	local slots, passive, menu = {}, {}, {}
	for i = 1, HT.SLOTS do
		local id = lo.slots[i]
		slots[#slots + 1] = i .. " " .. (id and HT.AbilityByID[id].name or "—")
	end
	for _, def in ipairs(HT.HunterAbilities) do
		if lo.state[def.id] == "p" then passive[#passive + 1] = def.name end
		if lo.state[def.id] == "m" then menu[#menu + 1] = def.name end
	end
	return table.concat(slots, "   ·   "),
		(#passive > 0 and table.concat(passive, ", ") or "none"),
		(#menu > 0 and table.concat(menu, ", ") or nil)
end

local KIND_TEXT = { active = "ACTIVE", toggle = "TOGGLE", passive = "PASSIVE" }
local KIND_COLOR = { active = C.cold, toggle = C.warn, passive = C.good }

-- Assign every hunter ability to Off / Slot 1-4 / Passive. Slots are unique.
local function LoadoutEditor(parent, stateMap, onChange)
	local combos = {}
	local function text(v)
		if v == nil then return "Off" end
		if v == "p" then return "Passive (always on)" end
		if v == "m" then return "Menu only" end
		return "Slot " .. v
	end
	local function refresh()
		for id, cb in pairs(combos) do cb:SetValue(text(stateMap[id])) end
	end

	for _, def in ipairs(HT.HunterAbilities) do
		local row = Row(parent, def.name)
		row:SetTooltip(def.desc)

		local cb = row:Add("DComboBox")
		cb:Dock(RIGHT)
		cb:SetWide(190)
		cb:AddChoice("Off", "off")
		for i = 1, HT.SLOTS do cb:AddChoice("Slot " .. i, i) end
		cb:AddChoice("Menu only", "m")
		if def.kind == "toggle" then cb:AddChoice("Passive (always on)", "p") end
		cb:SetValue(text(stateMap[def.id]))
		cb.OnSelect = function(_, _, _, data)
			local v = data ~= "off" and data or nil
			if isnumber(v) then
				for other, ov in pairs(stateMap) do
					if ov == v and other ~= def.id then stateMap[other] = nil end
				end
			end
			stateMap[def.id] = v
			refresh()
			onChange(stateMap)
		end
		combos[def.id] = cb

		local kind = row:Add("DLabel")
		kind:Dock(RIGHT)
		kind:SetWide(70)
		kind:SetText(KIND_TEXT[def.kind])
		kind:SetTextColor(KIND_COLOR[def.kind])
	end
end

local function SetHunterOnServer(ply, on)
	net.Start("HT_AdminSetHunter")
	net.WriteEntity(ply)
	net.WriteBool(on)
	net.SendToServer()
end

local function PickRole(name)
	net.Start("HT_PickRole")
	net.WriteString(name or "")
	net.SendToServer()
end

local function GameSet(key, value)
	timer.Create("HT_GameSet_" .. key, 0.3, 1, function()
		net.Start("HT_GameSet")
		net.WriteString(util.TableToJSON({ [key] = value }))
		net.SendToServer()
	end)
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
	return AddSlider(parent, label, cvar:GetMin() or 0, cvar:GetMax() or 100, decimals or 0, cvar:GetFloat(),
		function(v) SetServerCVar(cvar, v) end)
end

local function Refresh(delay)
	timer.Create("HT_MenuRefresh", delay or 0.3, 1, function()
		if IsValid(menuFrame) and menuFrame.ShowTab then menuFrame.ShowTab(state.tab, state.sub, true) end
	end)
end

------------------------------------------------------------------------
-- Personal hunter settings (Hunter > Default, and the gear in Players)
------------------------------------------------------------------------

local function DefaultSections(target)
	local isMe = target == LP()
	local sections = {
		{ "Slots", function(p)
			AddInfo(p, "Your own setup when no role is selected. Put up to 4 abilities on slots; toggles can also be passive.")
			LoadoutEditor(p, table.Copy(HT.ParseLoadout(Get(target, "HT_DefLoadout")).state), function(st)
				HT.SendSetting(target, "HT_DefLoadout", HT.SerializeLoadout(st))
			end)
		end },
		{ "Aim Assist", function(p)
			AddCheck(p, "Only while shooting / aiming", Get(target, "HT_AimOnFire"), function(v) HT.SendSetting(target, "HT_AimOnFire", v) end)
			AddCheck(p, "Also NPCs / nextbots (good for testing)", Get(target, "HT_AimNPC"), function(v) HT.SendSetting(target, "HT_AimNPC", v) end)
			AddSlider(p, "Strength", 0, CV.aimMaxStrength:GetFloat(), 2, Get(target, "HT_AimStrength"), function(v) HT.SendSetting(target, "HT_AimStrength", v) end)
			AddSlider(p, "Angle (degrees)", 1, CV.aimMaxFov:GetFloat(), 0, Get(target, "HT_AimFov"), function(v) HT.SendSetting(target, "HT_AimFov", v) end)
		end },
		{ "Radar", function(p)
			AddCheck(p, "Show names and distance", Get(target, "HT_ESPNames"), function(v) HT.SendSetting(target, "HT_ESPNames", v) end)
		end },
		{ "Chaser Pulse", function(p)
			AddSlider(p, "Radius (units)", 100, CV.chaserMaxRadius:GetFloat(), 0, Get(target, "HT_ChaserCfgRadius"), function(v) HT.SendSetting(target, "HT_ChaserCfgRadius", v) end)
			AddSlider(p, "Duration (seconds)", 1, CV.chaserMaxTime:GetFloat(), 1, Get(target, "HT_ChaserCfgTime"), function(v) HT.SendSetting(target, "HT_ChaserCfgTime", v) end)
		end },
	}
	if isMe then
		sections[#sections + 1] = { "Scary Sounds", function(p)
			local opts = {}
			for _, m in ipairs(HT.SoundModes) do
				if m.id ~= 4 or CV.soundAllowGlobal:GetBool() then opts[#opts + 1] = { m.name, m.id } end
			end
			AddCombo(p, "Play sounds", opts, HT.SoundMode:GetInt(), function(id) HT.SoundMode:SetInt(id) end)
			AddInfo(p, "Own sounds: put .wav/.mp3/.ogg files into addons/pulse/sound/pulse/ (marked with ★).")
		end }
	end
	return sections
end

------------------------------------------------------------------------
-- Tabs
------------------------------------------------------------------------

local function AbilityRow(p, def, prefix)
	local row = Row(p, prefix .. def.name, 28)
	local b = row:Add("DButton")
	b:Dock(RIGHT)
	b:SetWide(90)
	b:SetText(def.kind == "toggle" and "Toggle" or "Use")
	b.DoClick = function()
		HT.UseAbility(def.id)
		if def.id ~= "sounds" and IsValid(menuFrame) then menuFrame:Remove() end
	end
	AddInfo(p, def.desc)
end

local function AbilityList(p, me)
	local lo = HT.Loadout(me)
	local any = false
	for i = 1, HT.SLOTS do
		local id = lo.slots[i]
		if id then
			any = true
			AbilityRow(p, HT.AbilityByID[id], "[" .. HT.KeyName(HT.Keys["slot" .. i]:GetInt()) .. "]  ")
		end
	end
	if not any then AddInfo(p, "No abilities on your slots.") end
end

-- abilities without a key, only usable from here
local function MenuList(p, me)
	local lo = HT.Loadout(me)
	for _, id in ipairs(lo.menu) do AbilityRow(p, HT.AbilityByID[id], "[MENU]  ") end
	if #lo.menu == 0 then AddInfo(p, "No menu abilities.") end
end

local function PassiveList(p, me)
	local lo = HT.Loadout(me)
	local any = false
	for _, def in ipairs(HT.HunterAbilities) do
		if lo.state[def.id] == "p" then
			any = true
			AddInfo(p, def.name .. " — " .. def.desc, C.good)
		end
	end
	if not any then AddInfo(p, "No passive abilities.") end
end

local Tabs = {}

Tabs.keys = function()
	return { sections = {
		{ "General", function(p)
			AddBinder(p, "Open menu", HT.Keys.menu)
			AddInfo(p, "Tip: F5 also takes a screenshot in GMod. Pick another key here if that bothers you.")
		end },
		{ "Ability slots", function(p)
			for i = 1, HT.SLOTS do AddBinder(p, "Ability slot " .. i, HT.Keys["slot" .. i]) end
			AddInfo(p, "Hunters and victims use the same 4 keys. What a slot does depends on your role.")
		end },
		{ "Reset", function(p)
			AddButton(p, "Reset all keys to defaults", function()
				for name, cvar in pairs(HT.Keys) do RunConsoleCommand(cvar:GetName(), tostring(HT.KeyDefaults[name])) end
				Refresh(0.2)
			end)
		end },
	} }
end

Tabs.hunter = function(sub)
	local me = LP()
	local manager = HT.IsManager(me)

	if HT.InRound() then
		if not HT.IsHunter(me) then
			return { sections = { { "Hunter", function(p) AddInfo(p, "Only hunters can use this tab during a round.") end } } }
		end
		return { sections = {
			{ "Current role", function(p) AddInfo(p, "Role: " .. me:GetNWString("HT_RoleName", "?"), C.text) end },
			{ "Abilities", function(p) AbilityList(p, me) end },
			{ "Menu abilities", function(p) MenuList(p, me) end },
			{ "Passive", function(p) PassiveList(p, me) end },
		} }
	end

	local subs = { { "abilities", "Abilities" }, { "roles", "Roles" }, { "default", "Default" } }

	if sub == "roles" then
		return { subs = subs, sections = {
			{ "Choose a role", function(p)
				local current = me:GetNWString("HT_RoleName", "Default")
				local list = { { name = "Default", loadout = Get(me, "HT_DefLoadout"), default = true } }
				for _, r in ipairs(HT.Roles) do list[#list + 1] = r end
				for _, r in ipairs(list) do
					local slots, passive, menu = LoadoutSummary(r.loadout)
					local row, lbl = Row(p, r.name, 30)
					lbl:SetFont("HT_Tab")
					local b = row:Add("DButton")
					b:Dock(RIGHT)
					b:SetWide(110)
					b:SetText(current == r.name and "Selected" or "Select")
					b:SetEnabled(current ~= r.name)
					b.DoClick = function()
						PickRole(r.default and "" or r.name)
						Refresh()
					end
					AddInfo(p, slots)
					if menu then AddInfo(p, "Menu: " .. menu, C.cold) end
					AddInfo(p, "Passive: " .. passive, C.good)
				end
			end },
			{ "About roles", function(p)
				AddInfo(p, "Roles are presets made by the admin in Game > Role editor. Outside a round you can try them freely. \"Default\" uses your own setup from the Default tab.")
			end },
		} }
	elseif sub == "default" then
		return { subs = subs, sections = DefaultSections(me) }
	end

	return { subs = subs, sections = {
		{ "Hunter status", function(p)
			if HT.IsHunter(me) then
				AddInfo(p, "You are a hunter. Role: " .. me:GetNWString("HT_RoleName", "Default"), C.text)
				if manager then AddButton(p, "Stop being a hunter", function() SetHunterOnServer(me, false) Refresh() end) end
			else
				AddInfo(p, "You are not a hunter right now.")
				if manager then AddButton(p, "Make me a hunter", function() SetHunterOnServer(me, true) Refresh() end) end
			end
		end },
		{ "Abilities", function(p)
			if HT.IsHunter(me) then AbilityList(p, me) else AddInfo(p, "Become a hunter to use abilities.") end
		end },
		{ "Menu abilities", function(p)
			if HT.IsHunter(me) then MenuList(p, me) else AddInfo(p, "Become a hunter to use abilities.") end
		end },
		{ "Passive", function(p) PassiveList(p, me) end },
	} }
end

Tabs.victim = function()
	return { sections = {
		{ "Abilities", function(p)
			for _, def in ipairs(HT.VictimAbilities) do
				if def.kind == "active" then
					local enabled = def.allow:GetBool()
					local row = Row(p, "[" .. HT.KeyName(HT.Keys["slot" .. def.slot]:GetInt()) .. "]  " .. def.name .. (enabled and "" or "  (disabled)"), 28)
					if enabled and HT.IsVictim(LP()) then
						local b = row:Add("DButton")
						b:Dock(RIGHT)
						b:SetWide(90)
						b:SetText("Use")
						b.DoClick = function() HT.UseAbility(def.id) menuFrame:Remove() end
					end
					AddInfo(p, def.desc)
				end
			end
		end },
		{ "Passive", function(p)
			for _, def in ipairs(HT.VictimAbilities) do
				if def.kind == "passive" then
					AddInfo(p, def.name .. (def.allow:GetBool() and "" or " (disabled)") .. " — " .. def.desc, def.allow:GetBool() and C.good or C.faint)
				end
			end
			if CV.victimHeart:GetBool() then AddInfo(p, "Heartbeat — you hear your heart beat faster when a hunter is near.", C.good) end
		end },
		{ "Sanity & stamina", function(p)
			if CV.sanityEnabled:GetBool() then
				AddInfo(p, "Sanity starts at 100%. Damage, seeing the hunter and scares lower it. Stay close to other victims for a while to slowly raise it again.", C.text)
				AddInfo(p, "Low sanity: louder heartbeat, stamina drains faster, abilities take longer to recharge.")
				AddInfo(p, "At 0%: hallucinations, the hunter sometimes sees you through walls, your footprints last longer and even walking makes noise.")
			end
			if CV.staminaEnabled:GetBool() then
				AddInfo(p, "Stamina (during rounds): sprinting uses it up. When it is empty you can only walk until it has partly refilled.", C.text)
			end
		end },
	} }
end

local function OpenPlayerSettings(ply)
	if IsValid(playerFrame) then playerFrame:Remove() end
	if not IsValid(ply) then return end
	local f = NewFrame("Hunter settings: " .. ply:Nick(), 620, 540)
	playerFrame = f
	local body = f:Add("DPanel")
	body:Dock(FILL)
	body:SetPaintBackground(false)
	BuildSections(body, DefaultSections(ply))
end

Tabs.players = function()
	return { sections = {
		{ "Players", function(p)
			local inRound = HT.InRound()
			for _, ply in ipairs(player.GetAll()) do
				local row = Row(p, ply:Nick() .. (ply == LP() and "  (you)" or ""), 28)

				local gear = row:Add("DImageButton")
				gear:Dock(RIGHT)
				gear:DockMargin(8, 6, 4, 6)
				gear:SetWide(16)
				gear:SetImage("icon16/cog.png")
				gear:SetTooltip("Default hunter settings of " .. ply:Nick())
				gear.DoClick = function() OpenPlayerSettings(ply) end

				local pre = row:Add("DCheckBoxLabel")
				pre:Dock(RIGHT)
				pre:SetWide(110)
				pre:SetText("Next round")
				pre:SetTextColor(C.text)
				pre:SetValue(ply:GetNWBool("HT_Preselected", false))
				pre.OnChange = function(_, v)
					net.Start("HT_Preselect")
					net.WriteEntity(ply)
					net.WriteBool(v)
					net.SendToServer()
				end

				if inRound then
					local l = row:Add("DLabel")
					l:Dock(RIGHT)
					l:SetWide(90)
					l:SetText(HT.IsHunter(ply) and "Hunter" or "Victim")
					l:SetTextColor(HT.IsHunter(ply) and C.accent or C.muted)
				else
					local hunter = row:Add("DCheckBoxLabel")
					hunter:Dock(RIGHT)
					hunter:SetWide(90)
					hunter:SetText("Hunter")
					hunter:SetTextColor(C.text)
					hunter:SetValue(HT.IsHunter(ply))
					hunter.OnChange = function(_, v) SetHunterOnServer(ply, v) Refresh() end
				end
			end
		end },
		{ "Notes", function(p)
			AddInfo(p, "Hunter: make someone a hunter right now (outside of rounds, for testing).")
			AddInfo(p, "Next round: hunters for the next round when Game > Hunter selection is set to \"Preselected\".")
			AddInfo(p, "Gear: change that player's Default hunter settings.")
		end },
	} }
end

Tabs.server = function()
	return { sections = {
		{ "Hunter abilities", function(p)
			ServerSlider(p, "Aim assist: max strength", CV.aimMaxStrength, 2)
			ServerSlider(p, "Aim assist: max angle", CV.aimMaxFov)
			ServerSlider(p, "Chaser: max radius", CV.chaserMaxRadius)
			ServerSlider(p, "Chaser: max duration (s)", CV.chaserMaxTime, 1)
			ServerSlider(p, "Chaser: cooldown (s)", CV.chaserCooldown)
			ServerSlider(p, "Roar: radius", CV.roarRadius)
			ServerSlider(p, "Roar: victim speed", CV.roarSlow, 2)
			ServerSlider(p, "Roar: duration (s)", CV.roarDuration, 1)
			ServerSlider(p, "Roar: cooldown (s)", CV.roarCooldown)
			ServerSlider(p, "Teleport: range", CV.teleportRange)
			ServerSlider(p, "Teleport: cooldown (s)", CV.teleportCooldown)
			ServerSlider(p, "Noise radar: range", CV.noiseRadius)
			ServerSlider(p, "Footprints: range", CV.tracksRadius)
			ServerSlider(p, "Footprints: visible (s)", CV.tracksTime)
			ServerSlider(p, "Heartbeat sensor: range", CV.heartRange)
			ServerSlider(p, "Stalk: duration (s)", CV.stalkTime)
			ServerSlider(p, "Stalk: cooldown (s)", CV.stalkCooldown)
			ServerSlider(p, "Behind You: max distance", CV.behindRange)
			ServerSlider(p, "Behind You: max time behind (s)", CV.behindTime)
			ServerSlider(p, "Behind You: cooldown (s)", CV.behindCooldown)
			ServerSlider(p, "Jump scare: radius", CV.jumpRadius)
			ServerSlider(p, "Jump scare: face shown (s)", CV.jumpTime, 1)
			ServerSlider(p, "Jump scare: cooldown (s)", CV.jumpCooldown)
			AddInfo(p, "Which abilities a hunter has is set per role in Game > Role editor.")
		end },
		{ "Victim abilities", function(p)
			ServerCheck(p, "Flashlight blind", CV.allowFlash)
			ServerSlider(p, "Flashlight: range", CV.flashRange)
			ServerSlider(p, "Flashlight: blind duration (s)", CV.flashTime, 1)
			ServerSlider(p, "Flashlight: cooldown (s)", CV.flashCooldown)
			ServerCheck(p, "Stay silent", CV.allowSilent)
			ServerSlider(p, "Silent: duration (s)", CV.silentTime)
			ServerSlider(p, "Silent: cooldown (s)", CV.silentCooldown)
			ServerCheck(p, "Decoy", CV.allowDecoy)
			ServerSlider(p, "Decoy: cooldown (s)", CV.decoyCooldown)
			ServerCheck(p, "Adrenaline", CV.allowAdrenaline)
			ServerSlider(p, "Adrenaline: speed", CV.adrenalineSpeed, 2)
			ServerSlider(p, "Adrenaline: duration (s)", CV.adrenalineTime, 1)
			ServerSlider(p, "Adrenaline: cooldown (s)", CV.adrenalineCooldown)
			ServerCheck(p, "Hiding bonus", CV.allowHide)
			ServerSlider(p, "Hiding: crouch still for (s)", CV.hideTime)
		end },
		{ "Sanity", function(p)
			ServerCheck(p, "Victims have sanity", CV.sanityEnabled)
			ServerSlider(p, "Lost per point of damage", CV.sanityDamage, 1)
			ServerSlider(p, "Lost per second seeing a hunter", CV.sanitySee, 1)
			ServerSlider(p, "Scare abilities multiplier", CV.sanityScare, 1)
			ServerSlider(p, "Regained per second near others", CV.sanityRegen, 1)
			ServerSlider(p, "Seconds together before it rises", CV.sanityGroupTime)
			AddInfo(p, "Scares: Roar -10, Jump scare -25, turning around at Behind You -20, scary sound nearby -5 (times the multiplier).")
		end },
		{ "Stamina", function(p)
			ServerCheck(p, "Victims have stamina during rounds", CV.staminaEnabled)
			ServerSlider(p, "Seconds of sprint when full", CV.staminaSprint)
			ServerSlider(p, "Seconds to refill completely", CV.staminaRegen)
		end },
		{ "Victim heartbeat", function(p)
			ServerCheck(p, "Victims hear a heartbeat when a hunter is near", CV.victimHeart)
			ServerSlider(p, "Starts at distance", CV.victimHeartRange)
		end },
		{ "Scary sounds", function(p)
			ServerCheck(p, "Allow \"everywhere\" mode", CV.soundAllowGlobal)
			ServerSlider(p, "Cooldown (s)", CV.soundCooldown)
			ServerSlider(p, "Volume / reach", CV.soundLevel)
			ServerSlider(p, "Max distance for \"where I am looking\"", CV.soundRange)
		end },
	} }
end

local PHASE_TEXT = { lobby = "No round running.", prep = "Hiding phase running.", hunt = "Hunt running." }

Tabs.game = function()
	local g = HT.Game
	local roleOpts = {}
	for _, r in ipairs(HT.Roles) do roleOpts[#roleOpts + 1] = { r.name, r.name } end

	return { sections = {
		{ "Round", function(p)
			AddInfo(p, PHASE_TEXT[HT.Phase()] or "", C.text)
			if HT.InRound() then
				AddButton(p, "End round now", function()
					net.Start("HT_RoundCmd") net.WriteString("stop") net.SendToServer()
					Refresh(0.5)
				end)
			else
				AddButton(p, "Start round", function()
					net.Start("HT_RoundCmd") net.WriteString("start") net.SendToServer()
					menuFrame:Remove()
				end)
			end
			AddSlider(p, "Survival time (minutes)", 1, 60, 1, g.roundTime / 60, function(v) GameSet("roundTime", math.Round(v * 60)) end)
			AddCheck(p, "Hiding phase before the hunt", g.prepEnabled, function(v) GameSet("prepEnabled", v) end)
			AddSlider(p, "Hiding phase (seconds)", 5, 120, 0, g.prepTime, function(v) GameSet("prepTime", math.Round(v)) end)
			local weapons = {}
			for _, w in ipairs(HT.HunterWeapons) do weapons[#weapons + 1] = { w[2], w[1] } end
			AddCombo(p, "Hunter weapon", weapons, g.hunterWeapon, function(v) GameSet("hunterWeapon", v) end)
			AddInfo(p, "Victims get no weapons. Building, noclip and spawning are off during a round. Changes apply to the next round.")
		end },
		{ "Hunters", function(p)
			AddSlider(p, "Number of hunters", 1, 8, 0, g.hunterCount, function(v) GameSet("hunterCount", math.Round(v)) end)
			AddCombo(p, "Hunter selection", { { "Random", "random" }, { "Preselected", "preselected" } }, g.hunterSelect,
				function(v) GameSet("hunterSelect", v) end)
			AddInfo(p, "Preselected: tick \"Next round\" in the Players tab. Missing hunters are filled randomly.")
		end },
		{ "Role assignment", function(p)
			AddCombo(p, "Mode", { { "Fixed role", "fixed" }, { "Player choice", "choice" }, { "Random", "random" } }, g.roleMode,
				function(v) GameSet("roleMode", v) end)
			AddCombo(p, "Fixed role", roleOpts, g.fixedRole, function(v) GameSet("fixedRole", v) end)
			AddSlider(p, "Choice time (seconds)", 5, 60, 0, g.choiceTime, function(v) GameSet("choiceTime", math.Round(v)) end)
			AddInfo(p, "Player choice: hunters get a window at round start. No pick in time = random role.")
		end },
		{ "Role editor", function(p)
			local role = (editingRole ~= "__new") and (HT.FindRole(editingRole or "") or HT.Roles[1]) or nil
			local edit = {
				old = role and role.name or "",
				name = role and role.name or "New role",
				state = table.Copy(HT.ParseLoadout(role and role.loadout or "").state),
			}

			local opts = {}
			for _, r in ipairs(HT.Roles) do opts[#opts + 1] = { r.name, r.name } end
			opts[#opts + 1] = { "+ New role", "__new" }
			AddCombo(p, "Edit role", opts, role and role.name or "__new", function(v)
				editingRole = v
				Refresh(0)
			end)

			local nameRow = Row(p, "Name", 26)
			local te = nameRow:Add("DTextEntry")
			te:Dock(FILL)
			te:SetValue(edit.name)
			te.OnChange = function(s) edit.name = s:GetValue() end

			LoadoutEditor(p, edit.state, function() end)

			local buttons = p:Add("DPanel")
			buttons:Dock(TOP)
			buttons:DockMargin(0, 8, 0, 0)
			buttons:SetTall(30)
			buttons:SetPaintBackground(false)
			local function Btn(text, fn)
				local b = buttons:Add("DButton")
				b:Dock(LEFT)
				b:DockMargin(0, 0, 6, 0)
				b:SetWide(120)
				b:SetText(text)
				b.DoClick = fn
			end
			Btn("Save role", function()
				editingRole = string.Trim(edit.name)
				net.Start("HT_RoleSave")
				net.WriteString(util.TableToJSON({ old = edit.old, name = edit.name, loadout = HT.SerializeLoadout(edit.state) }))
				net.SendToServer()
			end)
			Btn("Duplicate", function()
				edit.old = ""
				edit.name = edit.name .. " copy"
				editingRole = edit.name
				net.Start("HT_RoleSave")
				net.WriteString(util.TableToJSON({ old = "", name = edit.name, loadout = HT.SerializeLoadout(edit.state) }))
				net.SendToServer()
			end)
			if role then
				Btn("Delete", function()
					editingRole = nil
					net.Start("HT_RoleDelete")
					net.WriteString(role.name)
					net.SendToServer()
				end)
			end
			AddInfo(p, "Each slot can hold one ability. Toggle abilities can also be passive (always on). Roles are saved on the server.")
		end },
	} }
end

------------------------------------------------------------------------
-- Main menu window
------------------------------------------------------------------------

local function VisibleTabs()
	local me = LP()
	local manager = HT.IsManager(me)
	local list = { { "keys", "Keybinds" } }
	if HT.IsHunter(me) or manager then list[#list + 1] = { "hunter", "Hunter" } end
	list[#list + 1] = { "victim", "Victim" }
	if manager then
		list[#list + 1] = { "players", "Players" }
		list[#list + 1] = { "server", "Server" }
		list[#list + 1] = { "game", "Game", right = true }
	end
	return list
end

function HT.OpenMenu(tab, sub)
	if IsValid(menuFrame) then menuFrame:Remove() menuFrame = nil return end
	HT.RequestSoundList()

	local f = NewFrame("PULSE – The Chase of the End", 860, 620)
	menuFrame = f

	local bar = f:Add("DPanel")
	bar:Dock(TOP)
	bar:SetTall(38)
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(C.line)
		surface.DrawLine(0, h - 1, w, h - 1)
	end

	local body = f:Add("DPanel")
	body:Dock(FILL)
	body:SetPaintBackground(false)

	local tabs = VisibleTabs()
	local valid = {}
	for _, t in ipairs(tabs) do valid[t[1]] = true end

	function f.ShowTab(id, s, keepScroll)
		if not valid[id] then id = "keys" end
		state.tab, state.sub = id, s or "abilities"

		local oldScroll = keepScroll and body.content and IsValid(body.content) and body.content:GetVBar():GetScroll()
		body:Clear()

		local def = Tabs[id](state.sub)
		if def.subs then
			local subbar = body:Add("DPanel")
			subbar:Dock(TOP)
			subbar:SetTall(36)
			subbar:SetPaintBackground(false)
			subbar:DockPadding(10, 6, 10, 4)
			for _, sb in ipairs(def.subs) do
				local b = subbar:Add("DButton")
				b:Dock(LEFT)
				b:DockMargin(0, 0, 6, 0)
				b:SetWide(110)
				b:SetText("")
				b.Paint = function(self, w, h)
					local on = state.sub == sb[1]
					draw.RoundedBox(12, 0, 0, w, h, on and Color(59, 29, 27) or Color(34, 27, 28))
					if on then
						surface.SetDrawColor(C.accent)
						surface.DrawOutlinedRect(0, 0, w, h)
					end
					draw.SimpleText(sb[2], "HT_Side", w / 2, h / 2, (on or self:IsHovered()) and C.text or C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				b.DoClick = function() f.ShowTab(id, sb[1]) end
			end
		end

		local inner = body:Add("DPanel")
		inner:Dock(FILL)
		inner:SetPaintBackground(false)
		body.content = BuildSections(inner, def.sections)
		if oldScroll then
			timer.Simple(0, function()
				if IsValid(body.content) then body.content:GetVBar():SetScroll(oldScroll) end
			end)
		end
	end

	for _, t in ipairs(tabs) do
		local b = bar:Add("DButton")
		b:Dock(t.right and RIGHT or LEFT)
		b:SetText("")
		surface.SetFont("HT_Tab")
		b:SetWide(surface.GetTextSize(string.upper(t[2])) + 32)
		b.Paint = function(self, w, h)
			local on = state.tab == t[1]
			if on then
				draw.RoundedBox(0, 0, 0, w, h, Color(28, 22, 23))
				surface.SetDrawColor(C.accent)
				surface.DrawRect(0, h - 3, w, 3)
			end
			draw.SimpleText(string.upper(t[2]), "HT_Tab", w / 2, h / 2 - 1, (on or self:IsHovered()) and C.text or C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		b.DoClick = function() f.ShowTab(t[1], "abilities") end
	end

	f.ShowTab(tab or state.tab, sub or state.sub)
end

-- Keep the open menu up to date when roles or game settings change
hook.Add("HT_DataUpdated", "HT_MenuRefresh", function()
	local focus = vgui.GetKeyboardFocus()
	if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end
	if state.tab == "game" or state.tab == "hunter" then Refresh(0.1) end
end)

------------------------------------------------------------------------
-- Scary sound picker
------------------------------------------------------------------------

function HT.OpenSoundPicker()
	if IsValid(soundFrame) then soundFrame:Remove() return end
	HT.RequestSoundList()
	if #HT.SoundNames == 0 then HT.Notify("No scary sounds found.") return end
	if IsValid(menuFrame) then menuFrame:Remove() end

	local f = NewFrame("Scary Sounds", 300, math.min(110 + #HT.SoundNames * 32, ScrH() - 80))
	soundFrame = f

	local scroll = NewScroll(f)
	scroll:Dock(FILL)

	local opts = {}
	for _, m in ipairs(HT.SoundModes) do
		if m.id ~= 4 or CV.soundAllowGlobal:GetBool() then opts[#opts + 1] = { m.name, m.id } end
	end
	local cb = scroll:Add("DComboBox")
	cb:Dock(TOP)
	cb:DockMargin(0, 6, 0, 8)
	cb:SetTall(24)
	for _, o in ipairs(opts) do cb:AddChoice(o[1], o[2], o[2] == HT.SoundMode:GetInt()) end
	cb.OnSelect = function(_, _, _, id) HT.SoundMode:SetInt(id) end

	for i, name in ipairs(HT.SoundNames) do
		AddButton(scroll, name, function()
			HT.PlayScarySound(i)
			f:Remove()
		end)
	end
	AddButton(scroll, "Random", function()
		HT.PlayScarySound(math.random(#HT.SoundNames))
		f:Remove()
	end)
end

------------------------------------------------------------------------
-- Role choice at round start
------------------------------------------------------------------------

net.Receive("HT_ChooseRole", function()
	local deadline = net.ReadFloat()
	if IsValid(roleFrame) then roleFrame:Remove() end
	if IsValid(menuFrame) then menuFrame:Remove() end

	local f = NewFrame("Choose your role", 560, 480)
	roleFrame = f
	f:ShowCloseButton(false)
	f.Think = function(self)
		local left = deadline - CurTime()
		self:SetTitle("Choose your role   " .. HT.FormatTime(left))
		if left <= 0 then self:Remove() end
	end

	local scroll = NewScroll(f)
	scroll:Dock(FILL)
	AddInfo(scroll, "Pick your role for this round. If you don't pick in time, you get a random one.", C.text)

	local function pick(name)
		PickRole(name)
		f:Remove()
	end
	for _, r in ipairs(HT.Roles) do
		local slots, passive, menu = LoadoutSummary(r.loadout)
		AddHeader(scroll, r.name)
		AddInfo(scroll, slots)
		if menu then AddInfo(scroll, "Menu: " .. menu, C.cold) end
		AddInfo(scroll, "Passive: " .. passive, C.good)
		AddButton(scroll, "Play as " .. r.name, function() pick(r.name) end)
	end
	AddButton(scroll, "Random role", function() pick(HT.Roles[math.random(#HT.Roles)].name) end)
end)

------------------------------------------------------------------------
-- Round results
------------------------------------------------------------------------

net.Receive("HT_RoundEnd", function()
	local data = util.JSONToTable(net.ReadString())
	if not istable(data) then return end
	if IsValid(endFrame) then endFrame:Remove() end
	if IsValid(roleFrame) then roleFrame:Remove() end

	local f = NewFrame("Round over", 620, 480)
	endFrame = f

	local titles = {
		hunter = { "HUNTER WINS", Color(224, 87, 76) },
		victims = { "VICTIMS WIN", C.good },
		none = { "ROUND STOPPED", C.muted },
	}
	local t = titles[data.winner] or titles.none

	local head = f:Add("DPanel")
	head:Dock(TOP)
	head:SetTall(92)
	head.Paint = function(_, w)
		draw.SimpleText(t[1], "HT_Big", w / 2, 30, t[2], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText((data.reason or "") .. "   Hunt time: " .. (data.duration or "0:00"), "HT_Side", w / 2, 68, C.muted,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local close = f:Add("DButton")
	close:Dock(BOTTOM)
	close:DockMargin(0, 8, 0, 0)
	close:SetTall(30)
	close:SetText("Close")
	close.DoClick = function() f:Remove() end

	local list = f:Add("DListView")
	list:Dock(FILL)
	list:SetMultiSelect(false)
	list:AddColumn("Player")
	list:AddColumn("Role")
	list:AddColumn("Survived"):SetFixedWidth(80)
	list:AddColumn("Result")
	for _, r in ipairs(data.rows or {}) do
		list:AddLine(r.name, r.role, r.survived, r.result)
	end

	surface.PlaySound(data.winner == "hunter" and "ambient/creatures/town_child_scream1.wav" or "ambient/levels/citadel/strange_talk1.wav")
end)
