
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRModule = require(ReplicatedStorage:WaitForChild('VRModule'))

VRModule:OnSignalEvent('UserCFrameEnabled', function(LocalPlayer, userCFrameEnum : Enum.UserCFrame, isEnabled)
	print(LocalPlayer.Name, userCFrameEnum.Name, isEnabled)
end)
