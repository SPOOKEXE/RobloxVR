
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VRModule = require(ReplicatedStorage:WaitForChild('VRModule'))

VRModule:Init()
VRModule:Start()
