-- PULSE: thrown glowstick, lights up the area for a while

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "PULSE Glowstick"
ENT.Spawnable = false

local LIFETIME = 60

function ENT:Initialize()
	self:SetModel("models/props_junk/garbage_plasticbottle003a.mdl")
	self:SetModelScale(0.5)
	self:SetColor(Color(90, 255, 120))
	self:SetMaterial("models/debug/debugwhite")
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end
		SafeRemoveEntityDelayed(self, LIFETIME)
	end
	self.Born = CurTime()
end

if CLIENT then
	function ENT:Draw()
		render.SuppressEngineLighting(true)
		self:DrawModel()
		render.SuppressEngineLighting(false)
	end

	function ENT:Think()
		local light = DynamicLight(self:EntIndex())
		if light then
			local fade = math.Clamp(1 - (CurTime() - (self.Born or CurTime())) / LIFETIME, 0.2, 1)
			light.pos = self:GetPos()
			light.r, light.g, light.b = 90, 255, 120
			light.brightness = 2 * fade
			light.decay = 1000
			light.size = 320
			light.dietime = CurTime() + 0.2
		end
	end
end
