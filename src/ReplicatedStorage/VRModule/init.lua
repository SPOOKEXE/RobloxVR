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

type AvailableEventNames =
	'UserCFrameChanged' | 'UserCFrameEnabled' | 'NavigationRequested' | 'TouchpadModeChanged' | 'InputBegan' | 'InputEnded' |
	'PressObjectAction' | 'HoldObjectAction' | 'ReleaseObjectAction' | 'OnObjectHoverEnter' | 'OnObjectHoverMove' | 'OnObjectHoverLeave'

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

	VRObjectAdded = SignalClassModule.New(),
	VRObjectRemoved = SignalClassModule.New(),
}

function Module:OnSignalEvent(EventName : AvailableEventNames, ...) : { RBXScriptConnection }
	local Connections = {}
	local CallbackEventClass = Module.Events[EventName]
	if CallbackEventClass then
		for _, callback in ipairs( {...} ) do
			-- ignore anything that is not a function
			if typeof(callback) ~= 'function' then
				continue
			end
			-- pcall to prevent errors from stopping the loop
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

function Module:FireSignal(EventName : AvailableEventNames, ...)
	local CallbackEventClass = Module.Events[EventName]
	if CallbackEventClass then
		CallbackEventClass:Fire(...)
	end
end

if RunService:IsServer() then

	local Players = game:GetService('Players')

	local ActiveVRObjectConfig = {}

	function Module:SetVRObjectConfig(TargetInstance, PropertyTable : VRObjectConfig, overwriteEntireTable : boolean?)
		if overwriteEntireTable or (not ActiveVRObjectConfig[TargetInstance]) then
			ActiveVRObjectConfig[TargetInstance] = { }
		end
		for propertyName, propertyValue in pairs( PropertyTable ) do
			ActiveVRObjectConfig[TargetInstance][propertyName] = propertyValue
		end
		TargetInstance:SetAttribute('ServerVRObject', true)
		CollectionService:AddTag(TargetInstance, 'ServerVRObject')
	end

	function Module:GetActiveVRObjectConfig(TargetInstance)
		return ActiveVRObjectConfig[TargetInstance]
	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ServerVRObject', nil)
		CollectionService:RemoveTag(TargetInstance, 'ServerVRObject')
		ActiveVRObjectConfig[TargetInstance] = nil
	end

	function Module:ToggleVRMovement(Enabled, TargetPlayers)
		if TargetPlayers then
			for _, LocalPlayer in ipairs( TargetPlayers ) do
				LocalPlayer:SetAttribute('VRMovement', Enabled)
				VREvent:FireClient(LocalPlayer, 'MovementToggle', Enabled)
			end
		else
			VREvent:FireAllClients('MovementToggle', Enabled)
			for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
				LocalPlayer:SetAttribute('VRMovement', Enabled)
			end
		end
	end

	function Module:AddExtensionSystem(extensionModule)
		extensionModule:Init(Module)
	end

else

	local VRService = game:GetService('VRService')
	--local ContextActionService = game:GetService('ContextActionService')
	local UserInputService = game:GetService('UserInputService')

	local ActiveVRObjectConfig = {}

	Module.VRMaid = MaidClassModule.New()
	Module.VREnabled = false

	function Module:SetVRObjectConfig(TargetInstance, PropertyTable : VRObjectConfig, overwriteEntireTable : boolean?)
		if overwriteEntireTable or (not ActiveVRObjectConfig[TargetInstance]) then
			ActiveVRObjectConfig[TargetInstance] = { }
		end
		for propertyName, propertyValue in pairs( PropertyTable ) do
			ActiveVRObjectConfig[TargetInstance][propertyName] = propertyValue
		end
		TargetInstance:SetAttribute('ClientVRObject', true)
		CollectionService:AddTag(TargetInstance, 'ClientVRObject')
		VREvent:FireAllClients('SetVRObjectConfig', TargetInstance, PropertyTable, overwriteEntireTable)
	end

	function Module:GetActiveVRObjectConfig(TargetInstance)
		return ActiveVRObjectConfig[TargetInstance]
	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ClientVRObject', nil)
		CollectionService:RemoveTag(TargetInstance, 'ClientVRObject')
		ActiveVRObjectConfig[TargetInstance] = nil
		VREvent:FireAllClients('RemoveVRObjectConfig', TargetInstance)
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
			VREvent:FireServer('TouchpadModeChanged', TouchpadEnum, TouchpadModeEnum)
		end))

		Module.VRMaid:Give(UserInputService.InputBegan:Connect(function(InputObject, WasProcessed)
			VREvent:FireServer('InputBegan', InputObject, WasProcessed)
		end))

		Module.VRMaid:Give(UserInputService.InputEnded:Connect(function(InputObject, WasProcessed)
			VREvent:FireServer('InputEnded', InputObject, WasProcessed)
		end))
	end

	function Module:Disable()
		Module.VRMaid:Cleanup()
	end

	function Module:AddExtensionSystem(extensionModule)
		extensionModule:Init(Module)
		if Module.VREnabled then
			extensionModule:Start()
		end
	end

	VREvent.OnClientEvent:Connect(function(Job, ...)
		--local Args = {...}
		if Job == 'SetVRObjectConfig' then
			Module:SetVRObjectConfig(...)
		elseif Job == 'RemoveVRObjectConfig' then
			Module:RemoveVRObject(...)
		end
	end)

	VRFunction.OnClientInvoke = function(Job, ...)
		local Args = {...}

	end

end

return Module
