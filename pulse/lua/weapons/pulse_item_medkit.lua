AddCSLuaFile()

SWEP.Base = "pulse_item_base"
SWEP.PrintName = "Medkit"
SWEP.SlotPos = 2
SWEP.WorldModel = "models/items/healthkit.mdl"
SWEP.HelpText = "Left click: +50 health"

function SWEP:UseItem(owner)
	if owner:Health() >= owner:GetMaxHealth() then owner:ChatPrint("[PULSE] You are not hurt.") return false end
	owner:SetHealth(math.min(owner:GetMaxHealth(), owner:Health() + 50))
	owner:EmitSound("items/smallmedkit1.wav", 60)
	return true
end
