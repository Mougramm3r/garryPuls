-- Hunter Tools: game mode (rounds), roles and saved settings

local HT = HunterTools

for _, name in ipairs({
	"HT_Data", "HT_GameSet", "HT_RoleSave", "HT_RoleDelete", "HT_RoundCmd",
	"HT_PickRole", "HT_ChooseRole", "HT_RoundEnd", "HT_Preselect",
}) do
	util.AddNetworkString(name)
end

------------------------------------------------------------------------
-- Saving roles and game settings (data/hunter_tools/)
------------------------------------------------------------------------

local DIR = "hunter_tools"
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
	return out
end

local function Load()
	local roles = util.JSONToTable(file.Read(ROLES_FILE, "DATA") or "")
	if istable(roles) and #roles > 0 then
		HT.Roles = {}
		for _, r in ipairs(roles) do
			local name = CleanRoleName(r.name)
			if name ~= "" and not HT.FindRole(name) then
				HT.Roles[#HT.Roles + 1] = { name = name, loadout = HT.SerializeLoadout(HT.ParseLoadout(r.loadout).state) }
			end
		end
	end
	if #HT.Roles == 0 then HT.Roles = table.Copy(HT.DefaultRoles) end

	local g = util.JSONToTable(file.Read(GAME_FILE, "DATA") or "")
	local merged = table.Copy(HT.GameDefaults)
	if istable(g) then table.Merge(merged, g) end
	HT.Game = ValidateGame(merged)
end
Load()

local function SendData(target)
	net.Start("HT_Data")
	net.WriteString(util.TableToJSON({ roles = HT.Roles, game = HT.Game }))
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
	if name == "" then ply:ChatPrint("[Hunter] The role needs a name.") return end

	local existing = HT.FindRole(name)
	local role = HT.FindRole(oldName)
	if existing and existing ~= role then
		ply:ChatPrint("[Hunter] A role called " .. name .. " already exists.")
		return
	end

	local loadout = HT.SerializeLoadout(HT.ParseLoadout(data.loadout).state)
	if role then
		role.name = name
		role.loadout = loadout
		if HT.Game.fixedRole == oldName then HT.Game.fixedRole = name end
		for _, p in ipairs(player.GetAll()) do
			if p.HT_SelectedRole == oldName then p.HT_SelectedRole = name end
			if p.HT_RoundRole == oldName then p.HT_RoundRole = name end
		end
	else
		if #HT.Roles >= 20 then ply:ChatPrint("[Hunter] You can have at most 20 roles.") return end
		HT.Roles[#HT.Roles + 1] = { name = name, loadout = loadout }
	end

	Save()
	SendData()
	RefreshAll()
	ply:ChatPrint("[Hunter] Role " .. name .. " saved.")
end)

net.Receive("HT_RoleDelete", function(_, ply)
	if not HT.IsManager(ply) then return end
	local name = CleanRoleName(net.ReadString())
	if #HT.Roles <= 1 then ply:ChatPrint("[Hunter] At least one role must stay.") return end
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
	ply:ChatPrint("[Hunter] Your role: " .. role.name)
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
	round.huntStart = CurTime()
	SetPhase("hunt", HT.Game.roundTime)
	for _, ply in ipairs(Participants(true)) do ply:Freeze(false) end
	PrintMessage(HUD_PRINTCENTER, "The hunt begins!")
	PrintMessage(HUD_PRINTTALK, "[Hunter] The hunt begins! Survive for " .. HT.FormatTime(HT.Game.roundTime) .. ".")
end

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

	net.Start("HT_RoundEnd")
	net.WriteString(util.TableToJSON({
		winner = winner,
		reason = reason,
		duration = HT.FormatTime(now - huntStart),
		rows = rows,
	}))
	net.Broadcast()

	round = nil
	SetPhase("lobby")
	SetGlobalString("HT_HunterNames", "")

	for _, ply in ipairs(player.GetAll()) do
		ply.HT_RoundRole = nil
		ply:Freeze(false)
		HT.SetHunter(ply, false, true)
		HT.RefreshLoadout(ply)
		if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then
			timer.Simple(0.2, function() Respawn(ply) end)
		end
	end
end
HT.EndRound = EndRound

local function StartRound(admin)
	if round then return end
	local plys = player.GetAll()
	if #plys < 2 then
		if IsValid(admin) then admin:ChatPrint("[Hunter] You need at least 2 players to start a round.") end
		return
	end

	local g = HT.Game
	local count = math.Clamp(g.hunterCount, 1, #plys - 1)

	-- pick hunters: preselected first, then random
	local hunters, rest = {}, {}
	for _, ply in ipairs(plys) do
		if g.hunterSelect == "preselected" and ply:GetNWBool("HT_Preselected", false) and #hunters < count then
			hunters[#hunters + 1] = ply
		else
			rest[#rest + 1] = ply
		end
	end
	table.Shuffle(rest)
	while #hunters < count do hunters[#hunters + 1] = table.remove(rest) end

	round = { players = {}, started = CurTime() }
	local isHunter = {}
	for _, h in ipairs(hunters) do isHunter[h] = true end

	local names = {}
	for _, ply in ipairs(plys) do
		ply.HT_RoundRole = nil
		HT.SetHunter(ply, false, true)
		HT.ResetAbilityState(ply)
		round.players[ply] = { name = ply:Nick(), hunter = isHunter[ply] or false, catches = 0 }
		if isHunter[ply] then names[#names + 1] = ply:Nick() end
	end
	SetGlobalString("HT_HunterNames", table.concat(names, ", "))

	-- prep phase: hiding time, also covers the role choice
	local prep = g.prepEnabled and g.prepTime or 0
	if g.roleMode == "choice" then prep = math.max(prep, g.choiceTime) end
	SetPhase(prep > 0 and "prep" or "hunt", prep)

	for _, h in ipairs(hunters) do HT.SetHunter(h, true, true) end
	for _, ply in ipairs(plys) do Respawn(ply) end

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

	PrintMessage(HUD_PRINTTALK, "[Hunter] Round started. " .. (#names > 1 and "Hunters: " or "Hunter: ") .. table.concat(names, ", "))
	if prep > 0 then
		timer.Simple(0.3, function()
			for _, h in ipairs(hunters) do if IsValid(h) then h:Freeze(true) end end
		end)
		PrintMessage(HUD_PRINTCENTER, "Hide! The hunter comes in " .. prep .. " seconds.")
	else
		StartHunt()
	end
end

net.Receive("HT_RoundCmd", function(_, ply)
	if not HT.IsManager(ply) then return end
	local cmd = net.ReadString()
	if cmd == "start" then
		StartRound(ply)
	elseif cmd == "stop" then
		EndRound("none", "Round stopped by " .. ply:Nick() .. ".")
	end
end)

-- Hunter picks a role: in the choice window during a round, or freely outside of rounds
net.Receive("HT_PickRole", function(_, ply)
	local name = net.ReadString()
	if round then
		local p = round.players[ply]
		if not p or not p.hunter or p.roleName then return end
		if HT.Game.roleMode ~= "choice" or CurTime() > (round.choiceEnd or 0) then return end
		AssignRole(ply, name)
	else
		ply.HT_SelectedRole = HT.FindRole(name) and name or nil
		HT.RefreshLoadout(ply)
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
	local attacker = dmg:GetAttacker()
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
