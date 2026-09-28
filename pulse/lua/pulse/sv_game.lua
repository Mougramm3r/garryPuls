-- PULSE: game mode (rounds), roles and saved settings

local HT = Pulse

for _, name in ipairs({
	"HT_Data", "HT_GameSet", "HT_RoleSave", "HT_RoleDelete", "HT_RoundCmd",
	"HT_PickRole", "HT_ChooseRole", "HT_RoundEnd", "HT_Preselect",
}) do
	util.AddNetworkString(name)
end
util.AddNetworkString("HT_PickPill")

------------------------------------------------------------------------
-- Saving roles and game settings (data/pulse/)
------------------------------------------------------------------------

local DIR = "pulse"
local ROLES_FILE = DIR .. "/roles.json"
local GAME_FILE = DIR .. "/game.json"

local function Save()
	file.CreateDir(DIR)
	file.Write(ROLES_FILE, util.TableToJSON(HT.Roles, true))
	file.Write(GAME_FILE, util.TableToJSON(HT.Game, true))
end

local function CleanRoleName(name)
	name = string.Trim(tostring(name or ""))
	name = string.gsub(name, "[^%w%s%-_]", "")
	return string.sub(name, 1, 24)
end

-- Pill Pack character name (letters, digits, _ -), empty = none
local function CleanPill(name)
	name = tostring(name or "")
	if #name > 64 or string.find(name, "[^%w_%-]") then return "" end
	return name
end

local function ValidateGame(g)
	local d = HT.GameDefaults
	local out = {}
	out.roundTime = math.Clamp(math.floor(tonumber(g.roundTime) or d.roundTime), 30, 3600)
	out.prepEnabled = g.prepEnabled == true or g.prepEnabled == 1
	out.prepTime = math.Clamp(math.floor(tonumber(g.prepTime) or d.prepTime), 5, 300)
	out.hunterCount = math.Clamp(math.floor(tonumber(g.hunterCount) or d.hunterCount), 1, 16)
	out.hunterSelect = (g.hunterSelect == "preselected") and "preselected" or "random"
	out.roleMode = (g.roleMode == "fixed" or g.roleMode == "random") and g.roleMode or "choice"
	out.fixedRole = CleanRoleName(g.fixedRole or d.fixedRole)
	out.choiceTime = math.Clamp(math.floor(tonumber(g.choiceTime) or d.choiceTime), 5, 60)
	out.hunterWeapon = d.hunterWeapon
	for _, w in ipairs(HT.HunterWeapons) do
		if w[1] == g.hunterWeapon then out.hunterWeapon = w[1] end
	end

	local function B(v, def)
		if v == nil then return def end
		return v == true or v == 1
	end
	out.finalPhase = B(g.finalPhase, d.finalPhase)
	out.finalBoost = math.Clamp(tonumber(g.finalBoost) or d.finalBoost, 0, 30)
	out.musicLast = math.Clamp(math.floor(tonumber(g.musicLast) or d.musicLast), 0, 600)
	out.ambient = B(g.ambient, d.ambient)
	out.ambientVolume = math.Clamp(tonumber(g.ambientVolume) or d.ambientVolume, 0, 1)
	out.items = B(g.items, d.items)
	out.itemCount = math.Clamp(math.floor(tonumber(g.itemCount) or d.itemCount), 0, 60)
	for _, item in ipairs(HT.Items) do out[item.key] = B(g[item.key], d[item.key]) end
	out.seriesMode = (g.seriesMode == "fixed") and "fixed" or "everyone"
	out.seriesRounds = math.Clamp(math.floor(tonumber(g.seriesRounds) or d.seriesRounds), 1, 50)
	out.seriesDelay = math.Clamp(math.floor(tonumber(g.seriesDelay) or d.seriesDelay), 5, 120)
	out.botsWalk = B(g.botsWalk, d.botsWalk)
	out.pillHidden = {}
	if istable(g.pillHidden) then
		local n = 0
		for pack, hidden in pairs(g.pillHidden) do
			if isstring(pack) and #pack <= 64 and n < 100 then
				out.pillHidden[pack] = hidden == true or hidden == 1
				n = n + 1
			end
		end
	end
	return out
end

local function Load()
	local roles = util.JSONToTable(file.Read(ROLES_FILE, "DATA") or "")
	if istable(roles) and #roles > 0 then
		HT.Roles = {}
		for _, r in ipairs(roles) do
			local name = CleanRoleName(r.name)
			if name ~= "" and not HT.FindRole(name) then
				HT.Roles[#HT.Roles + 1] = { name = name, loadout = HT.SerializeLoadout(HT.ParseLoadout(r.loadout).state), pill = CleanPill(r.pill) }
			end
		end
	end
	if #HT.Roles == 0 then HT.Roles = table.Copy(HT.DefaultRoles) end

	-- new example roles are added once to existing role files
	local added = util.JSONToTable(file.Read(DIR .. "/added_roles.json", "DATA") or "") or {}
	local changed = false
	for _, r in ipairs(HT.DefaultRoles) do
		if not added[r.name] then
			added[r.name] = true
			changed = true
			if not HT.FindRole(r.name) then HT.Roles[#HT.Roles + 1] = table.Copy(r) end
		end
	end
	if changed then
		file.CreateDir(DIR)
		file.Write(DIR .. "/added_roles.json", util.TableToJSON(added))
		file.Write(ROLES_FILE, util.TableToJSON(HT.Roles, true))
	end

	local g = util.JSONToTable(file.Read(GAME_FILE, "DATA") or "")
	local merged = table.Copy(HT.GameDefaults)
	if istable(g) then table.Merge(merged, g) end
	HT.Game = ValidateGame(merged)
end
Load()

-- Round series: several rounds with points, the hunter rotates
HT.Series = { active = false, round = 0, total = 0, scores = {} }

local function SendData(target)
	local series = HT.Series
	net.Start("HT_Data")
	net.WriteString(util.TableToJSON({
		roles = HT.Roles,
		game = HT.Game,
		series = { active = series.active, round = series.round, total = series.total },
	}))
	if target then net.Send(target) else net.Broadcast() end
end

hook.Add("PlayerInitialSpawn", "HT_Data", function(ply)
	timer.Simple(2, function() if IsValid(ply) then SendData(ply) end end)
end)

local function RefreshAll()
	for _, ply in ipairs(player.GetAll()) do HT.RefreshLoadout(ply) end
end

-- Admin: change game settings (applies from the next round)
net.Receive("HT_GameSet", function(_, ply)
	if not HT.IsManager(ply) then return end
	local changes = util.JSONToTable(net.ReadString())
	if not istable(changes) then return end
	local merged = table.Copy(HT.Game)
	for k, v in pairs(changes) do
		if HT.GameDefaults[k] ~= nil then merged[k] = v end
	end
	HT.Game = ValidateGame(merged)
	Save()
	SendData()
end)

-- Admin: create or update a role
net.Receive("HT_RoleSave", function(_, ply)
	if not HT.IsManager(ply) then return end
	local data = util.JSONToTable(net.ReadString())
	if not istable(data) then return end

	local oldName = CleanRoleName(data.old)
	local name = CleanRoleName(data.name)
	if name == "" then ply:ChatPrint("[PULSE] The role needs a name.") return end

	local existing = HT.FindRole(name)
	local role = HT.FindRole(oldName)
	if existing and existing ~= role then
		ply:ChatPrint("[PULSE] A role called " .. name .. " already exists.")
		return
	end

	local loadout = HT.SerializeLoadout(HT.ParseLoadout(data.loadout).state)
	local pill = CleanPill(data.pill)
	if role then
		role.name = name
		role.loadout = loadout
		role.pill = pill
		if HT.Game.fixedRole == oldName then HT.Game.fixedRole = name end
		for _, p in ipairs(player.GetAll()) do
			if p.HT_SelectedRole == oldName then p.HT_SelectedRole = name end
			if p.HT_RoundRole == oldName then p.HT_RoundRole = name end
		end
	else
		if #HT.Roles >= 20 then ply:ChatPrint("[PULSE] You can have at most 20 roles.") return end
		HT.Roles[#HT.Roles + 1] = { name = name, loadout = loadout, pill = pill }
	end

	Save()
	SendData()
	RefreshAll()
	ply:ChatPrint("[PULSE] Role " .. name .. " saved.")
end)

net.Receive("HT_RoleDelete", function(_, ply)
	if not HT.IsManager(ply) then return end
	local name = CleanRoleName(net.ReadString())
	if #HT.Roles <= 1 then ply:ChatPrint("[PULSE] At least one role must stay.") return end
	for i, r in ipairs(HT.Roles) do
		if r.name == name then
			table.remove(HT.Roles, i)
			break
		end
	end
	if not HT.FindRole(HT.Game.fixedRole) then HT.Game.fixedRole = HT.Roles[1].name end
	Save()
	SendData()
	RefreshAll()
end)

-- Admin: mark players as hunters for the next round ("Preselected")
net.Receive("HT_Preselect", function(_, ply)
	local target = net.ReadEntity()
	local state = net.ReadBool()
	if not HT.IsManager(ply) or not IsValid(target) or not target:IsPlayer() then return end
	target:SetNWBool("HT_Preselected", state)
end)

------------------------------------------------------------------------
-- Rounds
------------------------------------------------------------------------

local round -- nil when no round is running

local function SetPhase(phase, duration)
	SetGlobalString("HT_Phase", phase)
	SetGlobalFloat("HT_PhaseEnd", duration and CurTime() + duration or 0)
end
SetPhase("lobby")

local function Participants(wantHunter)
	local list = {}
	if not round then return list end
	for ply, p in pairs(round.players) do
		if IsValid(ply) and p.hunter == wantHunter then list[#list + 1] = ply end
	end
	return list
end

local function IsAliveInRound(ply)
	return IsValid(ply) and ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE
end

local function AssignRole(ply, name)
	if not round or not round.players[ply] then return end
	local role = HT.FindRole(name) or HT.Roles[math.random(#HT.Roles)]
	round.players[ply].roleName = role.name
	ply.HT_RoundRole = role.name
	HT.RefreshLoadout(ply)
	ply:ChatPrint("[PULSE] Your role: " .. role.name)

	-- the role's character from the Pill Pack; it brings its own attacks, so no hunter weapon
	if role.pill and role.pill ~= "" and HT.ApplyPill(ply, role.pill, true) then
		ply:StripWeapons()
		ply:ChatPrint("[PULSE] Your character: " .. (HT.PillPrintName(role.pill) or role.pill))
	end
end

-- Default role: the hunter's own setup, then they pick a character (Pill Pack)
local function AssignDefault(ply)
	local p = round and round.players[ply]
	if not p then return end
	p.roleName = "Default"
	ply.HT_RoundRole = nil
	ply.HT_RoundDefault = true
	HT.RefreshLoadout(ply)
	ply:ChatPrint("[PULSE] Your role: Default (your own setup)")
end

local function ApplyRoundPill(ply, pill)
	local p = round and round.players[ply]
	if not p or p.pillChosen then return end
	p.pillChosen = true
	pill = HT.ValidPill(pill)
	if pill ~= "" and HT.ApplyPill(ply, pill, true) then
		ply:StripWeapons()
		ply:ChatPrint("[PULSE] Your character: " .. (HT.PillPrintName(pill) or pill))
	end
end

local function AssignMissingRoles()
	for _, ply in ipairs(Participants(true)) do
		if not round.players[ply].roleName then
			AssignRole(ply, HT.Roles[math.random(#HT.Roles)].name)
		end
	end
end

local function Respawn(ply)
	if not IsValid(ply) then return end
	ply:UnSpectate()
	ply:Spawn()
end

local function StartHunt()
	if not round then return end
	AssignMissingRoles()
	-- Default hunters who didn't pick a character keep their saved one
	for _, ply in ipairs(Participants(true)) do
		if ply.HT_RoundDefault then ApplyRoundPill(ply, HT.Get(ply, "HT_DefPill")) end
	end
	round.huntStart = CurTime()
	SetPhase("hunt", HT.Game.roundTime)
	for _, ply in ipairs(Participants(true)) do ply:Freeze(false) end
	PrintMessage(HUD_PRINTCENTER, "The hunt begins!")
	PrintMessage(HUD_PRINTTALK, "[PULSE] The hunt begins! Survive for " .. HT.FormatTime(HT.Game.roundTime) .. ".")
end

local RemoveItems -- defined below (items on the map)

local function EndRound(winner, reason)
	if not round then return end
	local now = CurTime()
	local huntStart = round.huntStart or now

	local rows = {}
	for ply, p in pairs(round.players) do
		local alive = IsAliveInRound(ply) and not p.died
		local row = { name = p.name, hunter = p.hunter }
		if p.hunter then
			row.role = "Hunter · " .. (p.roleName or "?")
			row.survived = "—"
			row.result = (alive and "" or "Died, ") .. p.catches .. " caught"
			row.sort = -1
		else
			local t = math.max(0, (p.died or now) - huntStart)
			row.role = "Victim"
			row.survived = HT.FormatTime(t)
			row.result = alive and "Survived" or (p.result or "Died")
			row.alive = alive
			row.sort = alive and 1e6 or t
		end
		rows[#rows + 1] = row
	end
	table.sort(rows, function(a, b) return a.sort > b.sort end)
	for _, r in ipairs(rows) do r.sort = nil end

	-- series: points for this round
	local series = HT.Series
	local seriesInfo
	if series.active and winner ~= "none" then
		for ply, p in pairs(round.players) do
			local sc = series.scores[p.key]
			if not sc then
				sc = { name = p.name, points = 0, hunted = 0, catches = 0, survived = 0 }
				series.scores[p.key] = sc
			end
			if p.hunter then
				sc.hunted = sc.hunted + 1
				sc.catches = sc.catches + p.catches
				sc.points = sc.points + p.catches * 2 + (winner == "hunter" and 3 or 0)
			else
				local alive = IsAliveInRound(ply) and not p.died
				local t = math.max(0, (p.died or now) - huntStart)
				if alive then
					sc.survived = sc.survived + 1
					sc.points = sc.points + 3
				end
				sc.points = sc.points + math.floor(t / 60)
			end
		end
		series.round = series.round + 1

		local standings = {}
		for _, sc in pairs(series.scores) do standings[#standings + 1] = sc end
		table.sort(standings, function(a, b) return a.points > b.points end)

		local final = series.round >= series.total
		seriesInfo = { round = series.round, total = series.total, final = final, standings = standings,
			nextIn = not final and HT.Game.seriesDelay or nil }
		if final then
			series.active = false
		else
			SetGlobalFloat("HT_NextRound", now + HT.Game.seriesDelay)
			timer.Create("HT_SeriesNext", HT.Game.seriesDelay, 1, function()
				if HT.Series.active and HT.StartRound then HT.StartRound() end
			end)
		end
	elseif winner == "none" then
		series.active = false
		timer.Remove("HT_SeriesNext")
	end

	net.Start("HT_RoundEnd")
	net.WriteString(util.TableToJSON({
		winner = winner,
		reason = reason,
		duration = HT.FormatTime(now - huntStart),
		rows = rows,
		series = seriesInfo,
	}))
	net.Broadcast()

	RemoveItems()
	round = nil
	SetPhase("lobby")
	SetGlobalString("HT_HunterNames", "")
	SetGlobalBool("HT_Final", false)
	SendData()

	for _, ply in ipairs(player.GetAll()) do
		ply.HT_RoundRole = nil
		ply.HT_RoundDefault = nil
		ply:Freeze(false)
		HT.SetHunter(ply, false, true)
		HT.RefreshLoadout(ply)
		if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
			timer.Simple(0.2, function() Respawn(ply) end)
		end
	end
end
HT.EndRound = EndRound

local function PlayerKey(ply)
	return ply:IsBot() and ("BOT_" .. ply:Nick()) or ply:SteamID64() or ply:Nick()
end

local function SeriesScore(ply)
	local key = PlayerKey(ply)
	local sc = HT.Series.scores[key]
	if not sc then
		sc = { name = ply:Nick(), points = 0, hunted = 0, catches = 0, survived = 0 }
		HT.Series.scores[key] = sc
	end
	return sc
end

------------------------------------------------------------------------
-- Items on the map
------------------------------------------------------------------------

local SPAWN_CLASSES = { "info_player_start", "info_player_deathmatch", "info_player_combine", "info_player_rebel",
	"info_player_counterterrorist", "info_player_terrorist", "gmod_player_start" }

-- Random spots on the floor: from the navmesh if the map has one, otherwise around spawn points
local function RandomFloorSpot()
	if navmesh.IsLoaded() then
		local areas = navmesh.GetAllNavAreas()
		if #areas > 0 then
			local area = areas[math.random(#areas)]
			return area:GetRandomPoint()
		end
	end

	local spawns = {}
	for _, cls in ipairs(SPAWN_CLASSES) do
		for _, e in ipairs(ents.FindByClass(cls)) do spawns[#spawns + 1] = e:GetPos() end
	end
	for _, ply in ipairs(player.GetAll()) do spawns[#spawns + 1] = ply:GetPos() end
	if #spawns == 0 then return end

	local from = spawns[math.random(#spawns)] + Vector(0, 0, 40)
	local dir = Angle(0, math.random(0, 359), 0):Forward()
	local tr = util.TraceLine({ start = from, endpos = from + dir * math.random(150, 1500), mask = MASK_SOLID_BRUSHONLY })
	local base = tr.HitPos - dir * 24
	local down = util.TraceLine({ start = base, endpos = base - Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY })
	if down.Hit and down.HitNormal.z > 0.7 then return down.HitPos end
end

function RemoveItems()
	if round and round.items then
		for _, e in ipairs(round.items) do
			if IsValid(e) and not IsValid(e:GetOwner()) then e:Remove() end
		end
	end
	-- items still carried by players
	for _, ply in ipairs(player.GetAll()) do
		for _, item in ipairs(HT.Items) do
			if ply:HasWeapon(item.class) then ply:StripWeapon(item.class) end
		end
	end
end

local function SpawnItems()
	local g = HT.Game
	round.items = {}
	if not g.items or g.itemCount <= 0 then return end
	local classes = {}
	for _, item in ipairs(HT.Items) do
		if g[item.key] then classes[#classes + 1] = item.class end
	end
	if #classes == 0 then return end

	for _ = 1, g.itemCount do
		local pos
		for _ = 1, 6 do
			pos = RandomFloorSpot()
			if pos then break end
		end
		if pos then
			local ent = ents.Create(classes[math.random(#classes)])
			if IsValid(ent) then
				ent:SetPos(pos + Vector(0, 0, 12))
				ent:Spawn()
				round.items[#round.items + 1] = ent
			end
		end
	end
end

-- Only victims pick up items, and only one of each kind
hook.Add("PlayerCanPickupWeapon", "HT_Items", function(ply, wep)
	local cls = wep:GetClass()
	if string.StartWith(cls, "pulse_item_") then
		return HT.IsVictim(ply) and not ply:HasWeapon(cls)
	end
end)

local function StartRound(admin, opts)
	opts = opts or {}
	if round then return end
	local plys = player.GetAll()
	if #plys < 2 then
		if IsValid(admin) then
			admin:ChatPrint("[PULSE] You need at least 2 players to start a round.")
		else
			PrintMessage(HUD_PRINTTALK, "[PULSE] Not enough players for the next round. The series is over.")
			HT.Series.active = false
			SendData()
		end
		return
	end

	local g = HT.Game
	local count = math.Clamp(g.hunterCount, 1, #plys - 1)

	-- pick hunters: forced (test), series rotation, preselected, then random
	local hunters, rest = {}, {}
	if opts.hunters then
		hunters = opts.hunters
		for _, ply in ipairs(plys) do
			if not table.HasValue(hunters, ply) then rest[#rest + 1] = ply end
		end
	elseif HT.Series.active then
		-- whoever was hunter least often goes next
		table.Shuffle(plys)
		table.sort(plys, function(a, b) return SeriesScore(a).hunted < SeriesScore(b).hunted end)
		for i, ply in ipairs(plys) do
			if i <= count then hunters[#hunters + 1] = ply else rest[#rest + 1] = ply end
		end
	else
		for _, ply in ipairs(plys) do
			if g.hunterSelect == "preselected" and ply:GetNWBool("HT_Preselected", false) and #hunters < count then
				hunters[#hunters + 1] = ply
			else
				rest[#rest + 1] = ply
			end
		end
		table.Shuffle(rest)
		while #hunters < count do hunters[#hunters + 1] = table.remove(rest) end
	end

	round = { players = {}, started = CurTime() }
	local isHunter = {}
	for _, h in ipairs(hunters) do isHunter[h] = true end

	local names = {}
	for _, ply in ipairs(plys) do
		ply.HT_RoundRole = nil
		ply.HT_RoundDefault = nil
		HT.SetHunter(ply, false, true)
		HT.ResetAbilityState(ply)
		round.players[ply] = { name = ply:Nick(), hunter = isHunter[ply] or false, catches = 0, key = PlayerKey(ply) }
		if isHunter[ply] then names[#names + 1] = ply:Nick() end
	end
	SetGlobalString("HT_HunterNames", table.concat(names, ", "))

	round.victimCount = #plys - #hunters
	SetGlobalBool("HT_Final", false)
	SetGlobalFloat("HT_NextRound", 0)

	-- prep phase: hiding time, also covers the role choice
	local prep = g.prepEnabled and g.prepTime or 0
	if opts.prep then prep = opts.prep end
	if g.roleMode == "choice" then prep = math.max(prep, g.choiceTime) end
	SetPhase(prep > 0 and "prep" or "hunt", prep)

	for _, h in ipairs(hunters) do HT.SetHunter(h, true, true) end
	RemoveItems()
	for _, ply in ipairs(plys) do Respawn(ply) end
	SpawnItems()

	if g.roleMode == "fixed" then
		for _, h in ipairs(hunters) do AssignRole(h, g.fixedRole) end
	elseif g.roleMode == "random" then
		for _, h in ipairs(hunters) do AssignRole(h, HT.Roles[math.random(#HT.Roles)].name) end
	else
		round.choiceEnd = CurTime() + g.choiceTime
		net.Start("HT_ChooseRole")
		net.WriteFloat(round.choiceEnd)
		net.Send(hunters)
	end

	PrintMessage(HUD_PRINTTALK, "[PULSE] Round started. " .. (#names > 1 and "Hunters: " or "Hunter: ") .. table.concat(names, ", "))
	if prep > 0 then
		timer.Simple(0.3, function()
			for _, h in ipairs(hunters) do if IsValid(h) then h:Freeze(true) end end
		end)
		PrintMessage(HUD_PRINTCENTER, "Hide! The hunter comes in " .. prep .. " seconds.")
	else
		StartHunt()
	end
end

HT.StartRound = StartRound

local function StartSeries(admin)
	if round then return end
	local plys = player.GetAll()
	if #plys < 2 then
		if IsValid(admin) then admin:ChatPrint("[PULSE] You need at least 2 players to start a series.") end
		return
	end
	local g = HT.Game
	local total = g.seriesMode == "fixed" and g.seriesRounds or math.ceil(#plys / math.max(1, g.hunterCount))
	HT.Series = { active = true, round = 0, total = total, scores = {} }
	for _, ply in ipairs(plys) do SeriesScore(ply) end
	PrintMessage(HUD_PRINTTALK, "[PULSE] A series of " .. total .. " rounds begins!")
	SendData()
	StartRound(admin)
end

net.Receive("HT_RoundCmd", function(_, ply)
	if not HT.IsManager(ply) then return end
	local cmd = net.ReadString()
	if cmd == "start" then
		StartRound(ply)
	elseif cmd == "series" then
		StartSeries(ply)
	elseif cmd == "stop" then
		timer.Remove("HT_SeriesNext")
		HT.Series.active = false
		SetGlobalFloat("HT_NextRound", 0)
		if round then EndRound("none", "Stopped by " .. ply:Nick() .. ".") else SendData() end

	-- test mode
	elseif cmd == "testround" then
		StartRound(ply, { hunters = { ply }, prep = 5 })
	elseif cmd == "addbot" then
		RunConsoleCommand("bot")
	elseif cmd == "kickbots" then
		for _, b in ipairs(player.GetBots()) do b:Kick("Test finished") end
	elseif cmd == "items" then
		for _, item in ipairs(HT.Items) do
			local wep = ents.Create(item.class)
			if IsValid(wep) then
				wep:SetPos(ply:GetPos() + Vector(0, 0, 20))
				wep:Spawn()
			end
		end
	elseif cmd == "sanity0" then
		ply:SetNWFloat("HT_Sanity", 0)
	elseif cmd == "sanity100" then
		ply:SetNWFloat("HT_Sanity", 100)
	end
end)

-- Test mode: bots wander around, sometimes sprint or jump
hook.Add("StartCommand", "HT_TestBots", function(ply, cmd)
	if not ply:IsBot() or not HT.Game.botsWalk or not ply:Alive() then return end
	local now = CurTime()
	if now > (ply.HT_BotNext or 0) or ply:GetVelocity():Length2DSqr() < 20 ^ 2 and now > (ply.HT_BotStuck or 0) then
		ply.HT_BotNext = now + math.Rand(2, 5)
		ply.HT_BotStuck = now + 1
		ply.HT_BotYaw = math.random(0, 359)
		ply.HT_BotSprint = math.random() < 0.3
		ply.HT_BotCrouch = math.random() < 0.1
	end
	cmd:ClearMovement()
	cmd:ClearButtons()
	local ang = Angle(0, ply.HT_BotYaw or 0, 0)
	cmd:SetViewAngles(ang)
	ply:SetEyeAngles(ang)
	if ply.HT_BotCrouch then
		cmd:SetButtons(IN_DUCK)
	else
		cmd:SetForwardMove(ply.HT_BotSprint and 400 or 200)
		local buttons = ply.HT_BotSprint and IN_SPEED or 0
		if math.random() < 0.01 then buttons = bit.bor(buttons, IN_JUMP) end
		cmd:SetButtons(buttons)
	end
end)

-- Hunter picks a role: in the choice window during a round, or freely outside of rounds
net.Receive("HT_PickRole", function(_, ply)
	local name = net.ReadString()
	if round then
		local p = round.players[ply]
		if not p or not p.hunter or p.roleName then return end
		if HT.Game.roleMode ~= "choice" or CurTime() > (round.choiceEnd or 0) then return end
		if name == "" or name == "Default" then AssignDefault(ply) else AssignRole(ply, name) end
	else
		ply.HT_SelectedRole = HT.FindRole(name) and name or nil
		HT.RefreshLoadout(ply)
		-- outside rounds hunters can try the role's character (Default: their own saved one)
		if HT.IsHunter(ply) then
			HT.RemovePill(ply)
			local role = ply.HT_SelectedRole and HT.FindRole(ply.HT_SelectedRole)
			local pill = role and role.pill or (not role and HT.Get(ply, "HT_DefPill")) or ""
			if pill ~= "" then HT.ApplyPill(ply, pill, false) end
		end
	end
end)

-- Character pick for the Default role (the picker window with pictures)
net.Receive("HT_PickPill", function(_, ply)
	local pill = HT.ValidPill(net.ReadString())
	ply:SetNWString("HT_DefPill", pill) -- remembered for next time

	if round then
		local p = round.players[ply]
		if not p or not p.hunter or not ply.HT_RoundDefault then return end
		if HT.Phase() ~= "prep" and CurTime() > (round.choiceEnd or 0) + 30 then return end
		ApplyRoundPill(ply, pill)
	elseif HT.IsHunter(ply) and not ply.HT_SelectedRole then
		HT.RemovePill(ply)
		if pill ~= "" then HT.ApplyPill(ply, pill, false) end
	end
end)

local function CheckRound()
	if not round then return end
	local now = CurTime()

	if round.choiceEnd and now > round.choiceEnd then
		round.choiceEnd = nil
		AssignMissingRoles()
	end

	local huntersAlive, victimsAlive = 0, 0
	for ply, p in pairs(round.players) do
		if IsAliveInRound(ply) and not p.died then
			if p.hunter then huntersAlive = huntersAlive + 1 else victimsAlive = victimsAlive + 1 end
		end
	end

	-- final phase: only one victim left
	if HT.Phase() == "hunt" and HT.Game.finalPhase and not round.final and round.victimCount >= 2 and victimsAlive == 1 then
		round.final = true
		SetGlobalBool("HT_Final", true)
		for ply, p in pairs(round.players) do
			if not p.hunter and IsAliveInRound(ply) and not p.died then
				ply:SetNWFloat("HT_BoostFactor", 1.4)
				ply:SetNWFloat("HT_BoostUntil", now + HT.Game.finalBoost)
				PrintMessage(HUD_PRINTCENTER, "Final phase! Only " .. ply:Nick() .. " is left.")
			end
		end
	end

	if huntersAlive == 0 then
		EndRound("victims", "The hunter is dead.")
	elseif victimsAlive == 0 then
		EndRound("hunter", "All victims were caught.")
	elseif HT.Phase() == "prep" and now >= HT.PhaseEnd() then
		StartHunt()
	elseif HT.Phase() == "hunt" and now >= HT.PhaseEnd() then
		EndRound("victims", victimsAlive .. (victimsAlive == 1 and " victim" or " victims") .. " survived.")
	end
end
timer.Create("HT_RoundTick", 0.5, 0, CheckRound)

------------------------------------------------------------------------
-- Rules while a round is running
------------------------------------------------------------------------

hook.Add("PlayerDeath", "HT_RoundDeath", function(victim, _, attacker)
	if not round then return end
	attacker = HT.OwnerPlayer(attacker)
	local p = round.players[victim]
	if p and not p.died then
		p.died = CurTime()
		if not p.hunter then
			if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and HT.IsHunter(attacker) then
				p.result = "Caught by " .. attacker:Nick()
				local hp = round.players[attacker]
				if hp then hp.catches = hp.catches + 1 end
			else
				p.result = "Died"
			end
		end
	end
	timer.Simple(2, function()
		if round and IsValid(victim) and not victim:Alive() then victim:Spectate(OBS_MODE_ROAMING) end
	end)
	timer.Simple(0, CheckRound)
end)

-- Dead players stay spectators until the round ends
hook.Add("PlayerDeathThink", "HT_NoRespawn", function()
	if round then return false end
end)

-- Late joiners watch until the next round
hook.Add("PlayerSpawn", "HT_LateJoin", function(ply)
	if not round or round.players[ply] then return end
	timer.Simple(0, function()
		if round and IsValid(ply) and not round.players[ply] then
			ply:KillSilent()
			ply:Spectate(OBS_MODE_ROAMING)
		end
	end)
end)

-- Weapons: hunters get the hunter weapon, victims get nothing
hook.Add("PlayerLoadout", "HT_Loadout", function(ply)
	if not round then return end
	ply:StripWeapons()
	ply:StripAmmo()
	local p = round.players[ply]
	if p and p.hunter and HT.Game.hunterWeapon ~= "" then
		ply:Give(HT.Game.hunterWeapon)
	end
	return true
end)

-- Victims can't hurt hunters directly, hunters can't hurt each other
hook.Add("EntityTakeDamage", "HT_RoundDamage", function(target, dmg)
	if not round or not IsValid(target) or not target:IsPlayer() then return end
	local attacker = HT.OwnerPlayer(dmg:GetAttacker())
	if HT.Phase() == "prep" then return true end
	if HT.IsHunter(target) and IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then return true end
	if IsValid(attacker) and attacker:IsPlayer() and not HT.IsHunter(attacker) and attacker ~= target then return true end
end)

-- No sandbox building, noclip or spawning during a round
local function BlockInRound() if round then return false end end
for _, h in ipairs({
	"PlayerNoClip", "PlayerSpawnProp", "PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerGiveSWEP",
	"PlayerSpawnNPC", "PlayerSpawnVehicle", "PlayerSpawnEffect", "PlayerSpawnRagdoll", "PlayerSpawnObject",
}) do
	hook.Add(h, "HT_BlockInRound", BlockInRound)
end

hook.Add("PlayerDisconnected", "HT_RoundLeave", function(ply)
	if round and round.players[ply] then
		round.players[ply].died = round.players[ply].died or CurTime()
		round.players[ply].result = round.players[ply].result or "Left the game"
		timer.Simple(0, CheckRound)
	end
end)
