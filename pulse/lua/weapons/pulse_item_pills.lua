AddCSLuaFile()

SWEP.Base = "pulse_item_base"
SWEP.PrintName = "Calming Pills"
SWEP.SlotPos = 1
SWEP.WorldModel = "models/props_lab/jar01b.mdl"
SWEP.HelpText = "Left click: +30% sanity"

function SWEP:UseItem(owner)
	local HT = Pulse
	if not HT.CV.sanityEnabled:GetBool() then owner:ChatPrint("[PULSE] Sanity is off on this server.") return false end
	if HT.Sanity(owner) >= 100 then owner:ChatPrint("[PULSE] You feel calm already.") return false end
	owner:SetNWFloat("HT_Sanity", math.min(100, HT.Sanity(owner) + 30))
	Pulse.EmitSlot(owner, "pills", 60)
	return true
end
