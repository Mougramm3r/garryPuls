AddCSLuaFile()

SWEP.Base = "pulse_item_base"
SWEP.PrintName = "Glowstick"
SWEP.SlotPos = 3
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.HelpText = "Left click: throw, lights up the area"

function SWEP:Initialize()
	self:SetHoldType("grenade")
end

function SWEP:UseItem(owner)
	local ent = ents.Create("pulse_glowstick")
	if not IsValid(ent) then return false end
	ent:SetPos(owner:EyePos() + owner:GetAimVector() * 16)
	ent:SetAngles(owner:EyeAngles())
	ent:Spawn()
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then phys:SetVelocity(owner:GetAimVector() * 700 + owner:GetVelocity()) end
	owner:EmitSound("weapons/slam/throw.wav", 60)
	return true
end
