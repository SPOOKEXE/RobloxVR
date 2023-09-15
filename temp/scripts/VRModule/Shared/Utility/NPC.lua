local Debris = game:GetService('Debris')
local Players = game:GetService('Players')

-- // Module // --
local Module = {}

function Module.IsTargetWithinView(MyCharacter, TargetCharacter)
	local directionVector = CFrame.lookAt(MyCharacter:GetPivot().Position, TargetCharacter:GetPivot().Position).LookVector
	local distance = (MyCharacter:GetPivot().Position - TargetCharacter:GetPivot().Position).Magnitude

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = { MyCharacter }
	raycastParams.IgnoreWater = true

	local raycastResult = workspace:Raycast(MyCharacter:GetPivot().Position, directionVector * distance, raycastParams)
	return raycastResult and raycastResult.Instance:IsDescendantOf(TargetCharacter)
end

function Module.FindNearestPlayer(MyCharacter, MaxDistance, IgnoreDict)
	MaxDistance = MaxDistance or math.huge

	local TargetCharacter, TargetDistance = nil, nil
	for _, LocalPlayer in ipairs(Players:GetPlayers()) do
		if not LocalPlayer.Character or (IgnoreDict and IgnoreDict[LocalPlayer.Character]) then
			continue
		end

		if not Module.IsTargetWithinView(MyCharacter, LocalPlayer.Character) then
			continue
		end

		local DeltaPosition = (MyCharacter:GetPivot().Position - LocalPlayer.Character:GetPivot().Position)
		if DeltaPosition.Y > 8 then
			continue
		end

		local Distance = DeltaPosition.Magnitude
		local Humanoid = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
		if Humanoid.Health > 0 and Distance < MaxDistance then
			if TargetCharacter then
				if Distance < TargetDistance then
					TargetCharacter = LocalPlayer.Character
					TargetDistance = Distance
				end
			else
				TargetCharacter = LocalPlayer.Character
				TargetDistance = Distance
			end
		end
	end

	return TargetCharacter, TargetDistance
end

function Module.GeneratePathToPosition( PathObject : Path, Start, End )
	PathObject:ComputeAsync(Start, End)
	return PathObject.Status, PathObject:GetWaypoints()
end

local baseVisualNode = Instance.new('Part')
baseVisualNode.Anchored = true
baseVisualNode.CanCollide = false
baseVisualNode.CanTouch = false
baseVisualNode.CanQuery = false
baseVisualNode.CastShadow = false
baseVisualNode.Color = Color3.fromRGB(255, 238, 46)
baseVisualNode.Size = Vector3.new(0.5, 0.5, 0.5)
baseVisualNode.Material = Enum.Material.SmoothPlastic
function Module.VisualizePathWaypoints(pathWaypoints : {PathWaypoint})
	for _, waypoint in ipairs( pathWaypoints ) do
		local fakeNode = baseVisualNode:Clone()
		fakeNode.Position = waypoint.Position
		fakeNode.Parent = workspace
		Debris:AddItem(fakeNode, 1.5)
	end
end

return Module
