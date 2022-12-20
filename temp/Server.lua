
--[[

	Run via requiring this module with a script.

]]

local RunService = game:GetService('RunService')
if not RunService:IsServer() then
	warn('Run the server module with a normal script. ', debug.traceback())
	return {}
end

warn('Server For VR Initialized.')

local Players = game:GetService('Players')
repeat wait() until #Players:GetPlayers() > 0
local LocalPlayer = Players:GetPlayers()[1]

local VR_Objects = workspace:FindFirstChild('VR_Objects')
if VR_Objects then
	print('Setting VR_Objects Network Ownership to ', LocalPlayer.Name)
	for _,item in pairs(VR_Objects:GetDescendants()) do
		if item:IsA('BasePart') and not item.Anchored then
			item:SetNetworkOwner(LocalPlayer)
		end
	end
end

return true