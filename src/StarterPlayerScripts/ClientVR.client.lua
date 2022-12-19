
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRModule = require(ReplicatedStorage:WaitForChild('VRModule'))
local VRCharacter = require(ReplicatedStorage:WaitForChild('VRCharacter'))

local Terrain = workspace.Terrain

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

VRModule.Events.UserCFrameChanged:Connect(function(userCFrameEnum, cframeValue)
	if userCFrameEnum == Enum.UserCFrame.LeftHand then
		--LeftHandAttachment.WorldPosition = 
	elseif userCFrameEnum == Enum.UserCFrame.RightHand then

	elseif userCFrameEnum == Enum.UserCFrame.Head then

	end
end)

VRModule:Enable()

-- setup client-side attachments at hand / where head is looking
