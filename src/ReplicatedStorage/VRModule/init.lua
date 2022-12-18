local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')

local SharedModules = require(script.Shared)

local MaidClassModule = SharedModules.Classes.Maid
local SignalClassModule = SharedModules.Classes.Signal

local VREvent = SharedModules.Services.RemoteService:GetRemote('VREvent', 'RemoteEvent', false)
local VRFunction = SharedModules.Services.RemoteService:GetRemote('VRFunction', 'RemoteFunction', false)

type VRObjectConfig = {
	PressAction : boolean?,
	HoldAction : boolean?,
	ReleaseAction : boolean?,
	HoverMove : boolean?,
	HoverBegin : boolean?,
	HoverEnd : boolean?,
}

-- // Module // --
local Module = {}

Module.Events = {
	UserCFrameChanged = SignalClassModule.New(),
	UserCFrameEnabled = SignalClassModule.New(),
	NavigationRequested = SignalClassModule.New(),
	TouchpadModeChanged = SignalClassModule.New(),
	InputBegan = SignalClassModule.New(),
	InputEnded = SignalClassModule.New(),

	PressObjectAction = SignalClassModule.New(),
	HoldObjectAction = SignalClassModule.New(),
	ReleaseObjectAction = SignalClassModule.New(),
	OnObjectHoverEnter = SignalClassModule.New(),
	OnObjectHoverMove = SignalClassModule.New(),
	OnObjectHoverLeave = SignalClassModule.New(),
}

function Module:OnSignalEvent(EventName, ...) : { RBXScriptConnection }
	local Connections = {}
	local CallbackEventClass = Module.Events[EventName]
	if CallbackEventClass then
		for _, callback in ipairs( {...} ) do
			local success, err = pcall(function()
				table.insert( Connections, CallbackEventClass:Connect(callback) )
			end)
			if not success then
				warn(err)
			end
		end
	end
	return Connections
end

if RunService:IsServer() then

	function Module:SetVRObjectConfig(TargetInstance, PropertyTable : VRObjectConfig)
		-- set properties

		TargetInstance:SetAttribute('ServerVRObject', true)
		CollectionService:AddTag(TargetInstance, 'ServerVRObject')
	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ServerVRObject', nil)
		CollectionService:RemoveTag(TargetInstance, 'ServerVRObject')
		-- remove properties
	end

	function Module:PreventPlayerMovement(Enabled, TargetPlayers)
		if TargetPlayers then
			for _, LocalPlayer in ipairs( TargetPlayers ) do
				VREvent:FireClient(LocalPlayer, 'MovementToggle', Enabled)
			end
		else
			VREvent:FireAllClients('MovementToggle', Enabled)
		end
	end

else

	local VRService = game:GetService('VRService')
	--local ContextActionService = game:GetService('ContextActionService')
	local UserInputService = game:GetService('UserInputService')

	Module.VRMaid = MaidClassModule.New()
	Module.VREnabled = false

	function Module:SetVRObjectConfig(TargetInstance, PropertyTable : VRObjectConfig)
		TargetInstance:SetAttribute('ClientVRObject', true)

	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ClientVRObject', nil)
		
	end

	function Module:Enable()
		if Module.VREnabled then
			return
		end
		Module.VREnabled = true

		Module.VRMaid:Give(VRService.UserCFrameChanged:Connect(function(userCFrameEnum, cframeValue)
			VREvent:FireServer('UserCFrameChanged', userCFrameEnum, cframeValue)
		end))

		Module.VRMaid:Give(VRService.UserCFrameEnabled:Connect(function(userCFrameEnum, isEnabled)
			VREvent:FireServer('UserCFrameEnabled', userCFrameEnum, isEnabled)
		end))

		Module.VRMaid:Give(VRService.NavigationRequested:Connect(function(cframeValue, userCFrameEnum)
			VREvent:FireServer('NavigationRequested', userCFrameEnum, cframeValue)
		end))

		Module.VRMaid:Give(VRService.TouchpadModeChanged:Connect(function(TouchpadEnum, TouchpadModeEnum)
			VREvent:FireServer('TouchpadModeChanged', userCFrameEnum, cframeValue)
		end))

		Module.VRMaid:Give(UserInputService.InputBegan:Connect(function(InputObject, WasProcessed)
			
		end))

		Module.VRMaid:Give(UserInputService.InputEnded:Connect(function(InputObject, WasProcessed)
			
		end))
	end

	function Module:Disable()
		Module.VRMaid:Cleanup()
	end

	VREvent.OnClientEvent:Connect(function(Job, ...)
		local Args = {...}

	end)

	VRFunction.OnClientInvoke = function(Job, ...)
		local Args = {...}

	end

end

return Module
