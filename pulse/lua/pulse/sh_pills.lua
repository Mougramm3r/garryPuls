-- PULSE: optional support for Parakeet's Pill Pack and its character packs (FNAF, ...)
-- Everything here does nothing when the Pill Pack is not installed.

local HT = Pulse

function HT.PillsInstalled()
	return pk_pills ~= nil and pk_pills.getPillTable ~= nil
end

-- The Pill Pack keeps its list of pills private. getRandomForm() picks a random registered
-- pill, so calling it often enough finds all of them (getFormCount() tells us when we're done).
local pillList
function HT.GetPillList()
	if pillList then return pillList end
	if not HT.PillsInstalled() or not pk_pills.getRandomForm or not pk_pills.getFormCount then return {} end

	local total = pk_pills.getFormCount()
	local found, count = {}, 0
	for _ = 1, math.max(2000, total * 40) do
		local name = pk_pills.getRandomForm()
		if name and not found[name] then
			found[name] = true
			count = count + 1
			if count >= total then break end
		end
	end

	local list = {}
	for name in pairs(found) do
		local t = pk_pills.getPillTable(name)
		-- only pills a player wears as a character ("ply"), not vehicles/props ("phys")
		if t and t.type == "ply" then
			list[#list + 1] = { name = name, printName = t.printName or name }
		end
	end
	table.sort(list, function(a, b) return string.lower(a.printName) < string.lower(b.printName) end)
	if #list > 0 then pillList = list end -- try again later if the packs weren't loaded yet
	return list
end

function HT.PillPrintName(name)
	if not name or name == "" or not HT.PillsInstalled() then return nil end
	local t = pk_pills.getPillTable(name)
	return t and (t.printName or name) or nil
end

-- What the pill's own keys do, for the HUD
function HT.PillActions(name)
	if not name or name == "" or not HT.PillsInstalled() then return {} end
	local t = pk_pills.getPillTable(name)
	if not t then return {} end
	local out = {}
	if t.attack then out[#out + 1] = { "LMB", "Attack" } end
	if t.attack2 then out[#out + 1] = { "RMB", "Attack 2" } end
	if t.reload then out[#out + 1] = { "R", "Special" } end
	if t.cloak then out[#out + 1] = { "?", "Cloak" } end
	return out
end

-- Pill entities do the damage for their player; find that player
function HT.OwnerPlayer(ent)
	if not IsValid(ent) then return ent end
	if ent:IsPlayer() then return ent end
	if HT.PillsInstalled() and pk_pills.getMappedEnt then
		for _, ply in ipairs(player.GetAll()) do
			if pk_pills.getMappedEnt(ply) == ent then return ply end
		end
	end
	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then return owner end
	return ent
end

-- Model to show for jump scares and hallucinations (the character, if there is one)
function HT.VisualModel(ply)
	local m = ply:GetNWString("HT_VisualModel", "")
	return m ~= "" and m or ply:GetModel()
end

if CLIENT then return end

------------------------------------------------------------------------
-- Server: put hunters into their role's character and take it off again
------------------------------------------------------------------------

function HT.ApplyPill(ply, name, locked)
	if not HT.PillsInstalled() or not name or name == "" then return false end
	if not pk_pills.getPillTable(name) then return false end
	ply.HT_PillApplying = true
	pk_pills.apply(ply, name, locked and "lock-life" or "force")
	ply.HT_PillApplying = nil
	ply.HT_Pill = name
	ply:SetNWString("HT_PillName", name)
	timer.Simple(0.5, function()
		if not IsValid(ply) then return end
		local ent = pk_pills.getMappedEnt(ply)
		ply:SetNWString("HT_VisualModel", IsValid(ent) and ent:GetModel() or "")
	end)
	return true
end

function HT.RemovePill(ply)
	if not ply.HT_Pill then return end
	ply.HT_Pill = nil
	ply:SetNWString("HT_PillName", "")
	ply:SetNWString("HT_VisualModel", "")
	if HT.PillsInstalled() and IsValid(pk_pills.getMappedEnt(ply)) then
		pk_pills.restore(ply, true)
	end
end

-- During a round only characters given by PULSE are allowed (no switching in the Q menu)
timer.Create("HT_PillGuard", 1, 0, function()
	if not HT.PillsInstalled() or not HT.InRound() then return end
	for _, ply in ipairs(player.GetAll()) do
		local ent = pk_pills.getMappedEnt(ply)
		if IsValid(ent) and not ply.HT_Pill then
			pk_pills.restore(ply, true)
			ply:ChatPrint("[PULSE] Pills from the Q menu are disabled during a round.")
		end
	end
end)
