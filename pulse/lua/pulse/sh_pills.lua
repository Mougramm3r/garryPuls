-- PULSE: optional support for Parakeet's Pill Pack and its character packs (FNAF, ...)
-- Everything here does nothing when the Pill Pack is not installed.

local HT = Pulse

function HT.PillsInstalled()
	return pk_pills ~= nil and pk_pills.getPillTable ~= nil
end

-- Groups the Pill Pack itself brings (not the character packs you add)
HT.BASE_PILL_PACKS = { ["Half-Life 2"] = true, ["Fun"] = true, ["Jake"] = true }

-- The Pill Pack keeps its pack list private, but packStart() holds it as an upvalue.
local function PackTable()
	if not HT.PillsInstalled() or not pk_pills.packStart or not debug or not debug.getupvalue then return end
	for i = 1, 30 do
		local name, value = debug.getupvalue(pk_pills.packStart, i)
		if not name then return end
		if name == "packs" and istable(value) then return value end
	end
end

-- Fallback without pack info: getRandomForm() often enough finds every pill
local function SampleAllPills()
	local found = {}
	if not pk_pills.getRandomForm or not pk_pills.getFormCount then return found end
	local total, count = pk_pills.getFormCount(), 0
	for _ = 1, math.max(2000, total * 40) do
		local name = pk_pills.getRandomForm()
		if name and not found[name] then
			found[name] = true
			count = count + 1
			if count >= total then break end
		end
	end
	return found
end

-- All wearable characters ("ply" pills) with the pack they belong to
local allPills
local function AllPills()
	if allPills then return allPills end
	if not HT.PillsInstalled() then return {} end

	local list, seen = {}, {}
	local function add(name, pack)
		if seen[name] then return end
		local t = pk_pills.getPillTable(name)
		if t and t.type == "ply" then
			seen[name] = true
			list[#list + 1] = { name = name, printName = t.printName or name, pack = pack }
		end
	end

	local packs = PackTable()
	if packs then
		for _, pack in ipairs(packs) do
			for _, item in ipairs(pack.items or {}) do
				if item.type == "pill" and item.name then add(item.name, tostring(pack.name or "?")) end
			end
		end
	else
		for name in pairs(SampleAllPills()) do add(name, "?") end
	end

	table.sort(list, function(a, b) return string.lower(a.printName) < string.lower(b.printName) end)
	if #list > 0 then allPills = list end -- try again later if the packs weren't loaded yet
	return list
end

-- Is a pack hidden? The admin decides in Game > Characters; base packs are hidden by default.
function HT.PackHidden(pack)
	local hidden = HT.Game.pillHidden
	if istable(hidden) and hidden[pack] ~= nil then return hidden[pack] == true end
	return HT.BASE_PILL_PACKS[pack] == true
end

-- Packs with their number of characters, for the admin filter
function HT.GetPillPacks()
	local packs, order = {}, {}
	for _, pl in ipairs(AllPills()) do
		if not packs[pl.pack] then
			packs[pl.pack] = { name = pl.pack, count = 0 }
			order[#order + 1] = packs[pl.pack]
		end
		packs[pl.pack].count = packs[pl.pack].count + 1
	end
	return order
end

-- Characters that can be picked (hidden packs left out)
function HT.GetPillList()
	local list = {}
	for _, pl in ipairs(AllPills()) do
		if not HT.PackHidden(pl.pack) then list[#list + 1] = pl end
	end
	return list
end

-- A pill name that exists, is a wearable character and not in a hidden pack, or "" otherwise
function HT.ValidPill(name)
	name = tostring(name or "")
	if name == "" or #name > 64 or string.find(name, "[^%w_%-]") or not HT.PillsInstalled() then return "" end
	for _, pl in ipairs(HT.GetPillList()) do
		if pl.name == name then return name end
	end
	return ""
end

-- Picture for the character picker: the pack's icon like in the Q menu, otherwise nil (show the model)
function HT.PillIcon(name)
	if not HT.PillsInstalled() then return end
	local t = pk_pills.getPillTable(name)
	for _, path in ipairs({ t and t.icon, "pills/" .. name .. ".png", "entities/" .. name .. ".png" }) do
		if isstring(path) and path ~= "" and file.Exists("materials/" .. path, "GAME") then return path end
	end
end

function HT.PillModel(name)
	if not HT.PillsInstalled() then return end
	local t = pk_pills.getPillTable(name)
	return t and isstring(t.model) and t.model or nil
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
