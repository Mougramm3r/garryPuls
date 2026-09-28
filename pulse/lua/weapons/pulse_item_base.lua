-- PULSE: base for victim items. Items sit in the normal weapon inventory (mouse wheel),
-- left click uses them once.

AddCSLuaFile()

SWEP.PrintName = "PULSE Item"
SWEP.Author = "PULSE"
SWEP.Spawnable = false
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/items/healthkit.mdl"
SWEP.ViewModelFOV = 54

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HelpText = "Left click to use"

function SWEP:Initialize()
	self:SetHoldType("slam")
end

-- Returns true when the item was used up
function SWEP:UseItem() return true end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1)
	if CLIENT then return end
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if self:UseItem(owner) then
		owner:StripWeapon(self:GetClass())
	end
end

function SWEP:SecondaryAttack() end

function SWEP:DrawHUD()
	draw.SimpleTextOutlined(self.PrintName .. "  ·  " .. self.HelpText, "DermaDefaultBold", ScrW() / 2, ScrH() - 120,
		Color(236, 228, 223), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end
