AddCSLuaFile()

SWEP.Base = "pulse_item_base"
SWEP.PrintName = "Camera Flash"
SWEP.SlotPos = 4
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/maxofs2d/camera.mdl"
SWEP.HelpText = "Left click: blinds a hunter in front of you (one use)"

function SWEP:UseItem(owner)
	local HT = Pulse
	Pulse.EmitSlot(owner, "camera", 80)
	local eye, aim = owner:EyePos(), owner:GetAimVector()
	local blinded = {}
	for _, hunter in ipairs(player.GetAll()) do
		if HT.IsHunter(hunter) and hunter:Alive() then
			local dir = hunter:EyePos() - eye
			if dir:Length() < 900 then
				dir:Normalize()
				-- wider than the flashlight, and the hunter only has to roughly face you
				if aim:Dot(dir) > math.cos(math.rad(25)) and hunter:GetAimVector():Dot(-dir) > 0 then
					local tr = util.TraceLine({ start = eye, endpos = hunter:EyePos(), filter = { owner, hunter }, mask = MASK_VISIBLE })
					if not tr.Hit then blinded[#blinded + 1] = hunter end
				end
			end
		end
	end
	if #blinded > 0 then
		net.Start("HT_Blind")
		net.WriteFloat(HT.CV.flashTime:GetFloat() * 1.5)
		net.Send(blinded)
		owner:ChatPrint("[PULSE] Hunter blinded!")
	else
		owner:ChatPrint("[PULSE] The flash hit nobody.")
	end
	return true
end
