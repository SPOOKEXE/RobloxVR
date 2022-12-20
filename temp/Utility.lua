
local Module = {}

Module.BoneVisualiser = function(Container)
	local Beams = {}
	for _,Bone in pairs(Container:GetDescendants()) do
		local Prnt = Bone.Parent
		if Prnt.ClassName == Bone.ClassName and Bone:IsA('Bone') then
			local nBeam = script.Beam:Clone()
			nBeam.Attachment0 = Bone
			nBeam.Attachment1 = Prnt
			nBeam.Parent = Bone
			table.insert(Beams, nBeam)
		end
	end
	return Beams
end

function Module:SetPartOrModelCFrame(Target, CF)
	if Target:IsA('Model') and Target.PrimaryPart then
		Target:SetPrimaryPartCFrame(CF)
	elseif Target:IsA('BasePart') then
		Target.CFrame = CF
	end
end

function Module:GetPart(Obj)
	if Obj:IsA('Model') and Obj.PrimaryPart then
		return Obj.PrimaryPart
	end
	return Obj:IsA('BasePart') and Obj
end

function Module:FindClosestGrabbable(GrabTable, Position, MaxRange)
	if typeof(GrabTable) ~= 'table' or typeof(Position) ~= 'Vector3' then
		warn('GrabTable / Position invalid: ', GrabTable, Position)
		return nil
	end
	MaxRange = MaxRange or 3
	local Closest, CDist
	for _,Object in pairs(GrabTable) do
		local ObjPos = Module:GetPart(Object).Position
		local Dist = ObjPos and (ObjPos-Position).Magnitude
		if Dist then
			if Closest then
				if Dist < CDist then
					Closest = Object
					CDist = Dist
				end
			elseif Dist < MaxRange then
				Closest = Object
				CDist = Dist
			end
		end
	end
	return Closest
end

--[[
local Cache = {}
local function VisualAttachment(AttName, AttPosition, Color)
	Color = Color or Color3.fromRGB(0, 255, 0)
	if not Cache[AttName] then
		local part = Instance.new('Part')
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(.1,.1,.1)
		part.Color = Color
		part.Name = 'Attachment'
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Locked = true
		part.Parent = workspace.Terrain
		Cache[AttName] = part
	end
	if typeof(AttPosition) == 'CFrame' then
		AttPosition = AttPosition.Position
	end
	Cache[AttName].Position = AttPosition
	
	--if not Cache[AttName] then
	--	local nA = Instance.new('Attachment')
	--	nA.Visible = true
	--	nA.Parent = workspace.Terrain
	--	Cache[AttName] = nA
	--end
	--Cache[AttName].WorldPosition = AttPosition
	
end
]]

function Module:ResetVelocity(Model)
	if Model:IsA('BasePart') and not Model.Anchored then
		Model.Velocity = Vector3.new()
	end
	for _,o in pairs(Model:GetDescendants()) do
		if o:IsA('BasePart') and not o.Anchored then
			o.Velocity = Vector3.new()
		end
	end
end

return Module
