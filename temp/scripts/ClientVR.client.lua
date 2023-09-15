local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRService = game:GetService('VRService')
local VRModule = require(ReplicatedStorage:WaitForChild('VRModule'))
local VRCharacter = require(ReplicatedStorage:WaitForChild('VRCharacter'))

local Terrain = workspace.Terrain
local CurrentCamera = workspace.CurrentCamera

VRModule:AddExtensionSystem( VRCharacter )

local LeftHandAttachment = Instance.new('Attachment')
LeftHandAttachment.Visible = true
LeftHandAttachment.Parent = Terrain
local RightHandAttachment = Instance.new('Attachment')
RightHandAttachment.Visible = true
RightHandAttachment.Parent = Terrain
local HeadAttachment = Instance.new('Attachment')
HeadAttachment.Visible = true
HeadAttachment.Parent = Terrain

local LastHeadCFrame = CFrame.new()
local BodyCFrame = CFrame.new()
local ActiveCharacterInstance = false

VRModule:OnSignalEvent('VREnableToggle', function(IsEnabled)
	print('VRModule - ', IsEnabled and 'Enabled' or 'Disabled')
	if IsEnabled then
		-- LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		-- CurrentCamera.CameraType = Enum.CameraType.Scriptable
		VRModule.VRMaid:Give(RunService.Heartbeat:Connect(function()
			BodyCFrame = ActiveCharacterInstance and ActiveCharacterInstance:GetPivot() or CFrame.new()
			local ClampedYOffset = Vector3.new( 0, math.clamp(LastHeadCFrame.Y, -3, 3), 0 )
			local YLockedPositionOffset = Vector3.new(LastHeadCFrame.X, 0, LastHeadCFrame.Z)
			CurrentCamera.CFrame = BodyCFrame + (YLockedPositionOffset + ClampedYOffset)
		end))
	-- else
	-- 	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	-- 	CurrentCamera.CameraType = Enum.CameraType.Custom
	end
end)

local function onCFrameUpdated(userCFrameEnum, cframeValue)
	-- if typeof(userCFrameEnum) == 'EnumItem' then
	-- 	print('cframe update; ', userCFrameEnum.Name)
	-- end
	local CameraCFrame = CurrentCamera.CFrame
	if userCFrameEnum == Enum.UserCFrame.LeftHand then
		LeftHandAttachment.WorldPosition = (BodyCFrame * LastHeadCFrame * cframeValue).Position
	elseif userCFrameEnum == Enum.UserCFrame.RightHand then
		RightHandAttachment.WorldPosition = (BodyCFrame * LastHeadCFrame * cframeValue).Position
	elseif userCFrameEnum == Enum.UserCFrame.Head then
		HeadAttachment.WorldPosition = (BodyCFrame * cframeValue + (cframeValue.LookVector * 5)).Position
		LastHeadCFrame = cframeValue
	end
end

task.defer(onCFrameUpdated, nil, nil)
VRModule:OnSignalEvent('UserCFrameChanged', onCFrameUpdated)

local function onCharacterAdded(Character)
	if not Character then
		return
	end
	ActiveCharacterInstance = Character
end

task.defer(onCharacterAdded, LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if VRService.VREnabled then
	VRModule:Enable()
else
	VRModule:Disable()
end

VRService:GetPropertyChangedSignal('VREnabled'):Connect(function()
	if VRService.VREnabled then
		VRModule:Enable()
	else
		VRModule:Disable()
	end
end)