local Players = game:GetService('Players')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRModule = require(ReplicatedStorage:WaitForChild('VRModule'))
local VRCharacter = require(ReplicatedStorage:WaitForChild('VRCharacter'))

VRModule:AddExtensionSystem( VRCharacter )

local AssetsFolder = ReplicatedStorage.Assets
local SampleVRSword = AssetsFolder.Weapons.GreatSword:Clone()

local function onPlayerAdded(LocalPlayer)
	-- setup weapon in hand + replication or smthing
end

for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
	task.defer(onPlayerAdded, LocalPlayer)
end
Players.PlayerAdded:Connect(onPlayerAdded)
