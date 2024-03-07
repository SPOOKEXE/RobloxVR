
local RunService = game:GetService('RunService')

local Modules = require(script.Modules)

local LimbEnums = { Floor = 'Floor', Head = 'Head', LeftHand = 'LeftHand', RightHand = 'RightHand', }

export type VRComponent = { ID : string, CFrame : CFrame, OnCFrameUpdate : RBXScriptSignal }
export type VRFloor = VRComponent & { ID : 'Floor' }
export type VRLimb = VRComponent & { Enabled : RBXScriptSignal, Disabled : RBXScriptSignal, }
export type VRHand = VRLimb & { ID : 'LeftHand' | 'RightHand', }
export type VRHead = VRLimb & { ID : 'Head', }

-- // Module // --
local Module = {}

Module.LimbEnums = LimbEnums
Module.Modules = Modules

Modules.Events = {

}

function Module.Start()

end

function Module.Init()

end

return Module
