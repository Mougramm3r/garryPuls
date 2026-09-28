-- PULSE: hunter trap. Holds a victim in place and rattles loudly.

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "PULSE Trap"
ENT.Spawnable = false

local MODEL = "models/props_junk/sawblade001a.mdl"

function ENT:Initialize()
	self:SetModel(MODEL)
	self:SetColor(Color(70, 60, 55))
	if SERVER then
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
		self:SetAngles(Angle(0, self:GetAngles().y, 0))
	end
end

if SERVER then
	function ENT:Think()
		local HT = Pulse
		for _, ply in ipairs(ents.FindInSphere(self:GetPos(), 30)) do
			if ply:IsPlayer() and HT.IsVictim(ply) then
				self:Catch(ply)
				return
			end
		end
		self:NextThink(CurTime() + 0.1)
		return true
	end

	function ENT:Catch(ply)
		local HT = Pulse
		local hold = HT.CV.trapTime:GetFloat()
		ply:SetNWFloat("HT_RootUntil", CurTime() + hold)
		ply:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 100)
		ply:EmitSound("physics/metal/metal_chainlink_impact_hard1.wav", 100)
		util.ScreenShake(ply:GetPos(), 6, 10, 0.5, 100)

		local owner = self:GetOwner()
		ply:TakeDamage(10, IsValid(owner) and owner or self, self)
		HT.Scare(ply, 10)
		if HT.SendPing then HT.SendPing(ply:GetPos() + Vector(0, 0, 40), 3) end
		self:Remove()
	end
end
