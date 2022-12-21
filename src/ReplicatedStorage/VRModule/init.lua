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

local ExtensionModules = {}

-- // Module // --
local Module = {}

Module.SharedModules = SharedModules

Module.Events = {
	VREnableToggle = SignalClassModule.New(),

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
	local SignalClass = Module.Events[EventName]
	if SignalClass then
		SignalClass:Fire(...)
	end
end

if RunService:IsServer() then

	local Players = game:GetService('Players')

	local ServerModules = require(script.Server)

	local ActiveVRObjectConfig = {}

	Module.ServerModules = ServerModules

	function Module:DoesPlayerHaveVREnabled(LocalPlayer)
		return LocalPlayer:GetAttribute('VREnabled')
	end

	function Module:SetVRObjectOwnership(TargetInstance, OwnerInstance)
		local Descendants = TargetInstance:GetDescendants()
		table.insert(Descendants, TargetInstance)
		for _, basePart in ipairs( Descendants ) do
			if basePart:IsA('BasePart') then
				if basePart.Anchored then
					warn('BasePart is anchored, cannot set network ownership: ', basePart:GetFullName())
					continue
				end
				basePart:SetNetworkOwner(OwnerInstance)
			end
		end
	end

	function Module:SetVRObjectConfig(TargetInstance, PropertyTable : VRObjectConfig, overwriteEntireTable : boolean?)
		if overwriteEntireTable or (not ActiveVRObjectConfig[TargetInstance]) then
			ActiveVRObjectConfig[TargetInstance] = { }
		end
		for propertyName, propertyValue in pairs( PropertyTable ) do
			ActiveVRObjectConfig[TargetInstance][propertyName] = propertyValue
		end
		TargetInstance:SetAttribute('ServerVRObject', true)
		CollectionService:AddTag(TargetInstance, 'ServerVRObject')
		VREvent:FireAllClients('SetVRObjectConfig', TargetInstance, PropertyTable, overwriteEntireTable)
	end

	function Module:GetActiveVRObjectConfig(TargetInstance)
		return ActiveVRObjectConfig[TargetInstance]
	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ServerVRObject', nil)
		CollectionService:RemoveTag(TargetInstance, 'ServerVRObject')
		ActiveVRObjectConfig[TargetInstance] = nil
		VREvent:FireAllClients('RemoveVRObjectConfig', TargetInstance)
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
		table.insert(ExtensionModules, extensionModule)
		extensionModule:Init(Module)
	end

	local function HasArgTypes(OrderedArgs, OrderedTypes)
		for index = 1, #OrderedArgs do
			local compareTo = OrderedTypes[index] or OrderedTypes[#OrderedTypes]
			if OrderedTypes[index] and ( typeof(OrderedArgs[index]) ~= compareTo) then
				return false
			end
		end
		return true
	end

	local function ValidateInputObjectTable(Tbl)
		return HasArgTypes({Tbl, Tbl.KeyCode, Tbl.UserInputType}, {'EnumItem'})
	end

	VREvent.OnServerEvent:Connect(function(LocalPlayer, Job, ...)
		print(LocalPlayer.Name, Job)
		local Args = {...}
		if Job == 'ToggleVR' and HasArgTypes(Args, {'boolean'}) then
			print(LocalPlayer.Name, 'has toggled VR: ', Args[1])
			LocalPlayer:SetAttribute('VREnabled', Args[1])
			Module:FireSignal('VREnableToggle', LocalPlayer, ...)
		elseif Job == 'UserCFrameEnabled' and HasArgTypes(Args, {'EnumItem', 'CFrame'}) then
			Module:FireSignal('UserCFrameEnabled', LocalPlayer, ...)
		elseif Job == 'UserCFrameChanged' and HasArgTypes(Args, {'EnumItem', 'CFrame'}) then
			Module:FireSignal('UserCFrameChanged', LocalPlayer, ...)
		elseif Job == 'NavigationRequested' and HasArgTypes(Args, {'EnumItem', 'CFrame'}) then
			Module:FireSignal('NavigationRequested', LocalPlayer, ...)
		elseif Job == 'TouchpadModeChanged' and HasArgTypes(Args, {'EnumItem', 'EnumItem'}) then
			Module:FireSignal('TouchpadModeChanged', LocalPlayer, ...)
		elseif Job == 'TouchpadModeChanged' and HasArgTypes(Args, {'table', 'table'}) then
			Module:FireSignal('TouchpadModeChanged', LocalPlayer, ...)
		elseif Job == 'InputBegan' and HasArgTypes(Args, {'table', 'boolean'}) and ValidateInputObjectTable(Args[1]) then
			Module:FireSignal('InputBegan', LocalPlayer, ...)
		elseif Job == 'InputEnded' and HasArgTypes(Args, {'table', 'boolean'}) and ValidateInputObjectTable(Args[1]) then
			Module:FireSignal('InputEnded', LocalPlayer, ...)
		end
	end)

	VRFunction.OnServerInvoke = function(LocalPlayer, Job, ...)
		-- local Args = {...}

		return false
	end

else

	local VRService = game:GetService('VRService')
	--local ContextActionService = game:GetService('ContextActionService')
	local UserInputService = game:GetService('UserInputService')

	local Players = game:GetService('Players')
	local LocalPlayer = Players.LocalPlayer

	local ClientModules = require(script.Client)

	local CurrentCamera = workspace.CurrentCamera

	local ActiveVRObjectConfig = {}

	Module.ClientModules = ClientModules
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
	end

	function Module:GetActiveVRObjectConfig(TargetInstance)
		return ActiveVRObjectConfig[TargetInstance]
	end

	function Module:RemoveVRObject(TargetInstance)
		TargetInstance:SetAttribute('ClientVRObject', nil)
		CollectionService:RemoveTag(TargetInstance, 'ClientVRObject')
		ActiveVRObjectConfig[TargetInstance] = nil
	end

	local function InputObjectToTable(InputObject)
		return {KeyCode = InputObject.KeyCode, UserInputType = InputObject.UserInputType}
	end

	function Module:Enable()
		if Module.VREnabled then
			return
		end
		print(script.Name, 'Enabled')

		Module.VREnabled = true
		VREvent:FireServer('VRToggle', true)

		CurrentCamera.CameraType = Enum.CameraType.Scriptable -- allows camera manipulation
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		Module.VRMaid:Give(CurrentCamera:GetPropertyChangedSignal('CameraType'):Connect(function()
			CurrentCamera.CameraType = Enum.CameraType.Scriptable -- allows camera manipulation
		end))
		Module.VRMaid:Give(LocalPlayer:GetPropertyChangedSignal('CameraMode'):Connect(function()
			LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		end))

		-- local yValue = (2 + self.HeadClass.ActualHeadCFrame.Position.Y)
		-- 	yValue = yValue > 3 and 3 or yValue
		-- 	local origCF = self.CentreBlock.CFrame * CFrame.new(0, yValue, 0)
		-- 	self.Camera.CFrame = origCF
		-- 	Origin = origCF

		Module.VRMaid:Give(VRService.UserCFrameEnabled:Connect(function(userCFrameEnum, isEnabled)
			Module:FireSignal('UserCFrameEnabled', userCFrameEnum, isEnabled)
			VREvent:FireServer('UserCFrameEnabled', userCFrameEnum, isEnabled)
		end))

		Module.VRMaid:Give(VRService.UserCFrameChanged:Connect(function(userCFrameEnum, cframeValue)
			Module:FireSignal('UserCFrameChanged', userCFrameEnum, cframeValue)
			VREvent:FireServer('UserCFrameChanged', userCFrameEnum, cframeValue)
		end))

		Module.VRMaid:Give(VRService.NavigationRequested:Connect(function(cframeValue, userCFrameEnum)
			Module:FireSignal('NavigationRequested', userCFrameEnum, cframeValue)
			VREvent:FireServer('NavigationRequested', userCFrameEnum, cframeValue)
		end))

		Module.VRMaid:Give(VRService.TouchpadModeChanged:Connect(function(TouchpadEnum, TouchpadModeEnum)
			Module:FireSignal('TouchpadModeChanged', TouchpadEnum, TouchpadModeEnum)
			VREvent:FireServer('TouchpadModeChanged', TouchpadEnum, TouchpadModeEnum)
		end))

		Module.VRMaid:Give(UserInputService.InputBegan:Connect(function(InputObject, WasProcessed)
			Module:FireSignal('InputBegan', InputObject, WasProcessed)
			VREvent:FireServer('InputBegan', InputObjectToTable(InputObject), WasProcessed)
		end))

		Module.VRMaid:Give(UserInputService.InputEnded:Connect(function(InputObject, WasProcessed)
			Module:FireSignal('InputEnded', InputObject, WasProcessed)
			VREvent:FireServer('InputEnded', InputObjectToTable(InputObject), WasProcessed)
		end))

		Module.VRMaid:Give(function()
			Module:FireSignal('VREnabled', false)
			VREvent:FireServer('VRToggle', false)
			CurrentCamera.CameraType = Enum.CameraType.Custom
			for _, extension in ipairs( ExtensionModules ) do
				extension:Disable()
			end
		end)

		Module:FireSignal('VREnabled', true)
		for _, extension in ipairs( ExtensionModules ) do
			extension:Enable()
		end
	end

	function Module:Disable()
		print(script.Name, 'Disabled')
		Module.VRMaid:Cleanup()
	end

	function Module:AddExtensionSystem(extensionModule)
		extensionModule:Init(Module)
		table.insert(ExtensionModules, extensionModule)
		if Module.VREnabled then
			extensionModule:Start()
		end
	end

	VREvent.OnClientEvent:Connect(function(Job, ...)
		--local Args = {...}
		print('OnClientEvent; ', Job)
		if Job == 'SetVRObjectConfig' then
			Module:SetVRObjectConfig(...)
		elseif Job == 'RemoveVRObjectConfig' then
			Module:RemoveVRObject(...)
		end
	end)

	VRFunction.OnClientInvoke = function(Job, ...)
		local Args = {...}
		print('OnClientInvoke; ', Job)
		return false
	end

end

return Module
