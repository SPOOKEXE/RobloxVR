local RunService = game:GetService('RunService')
local VRService = game:GetService('VRService')
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRUtility = require(ReplicatedStorage:WaitForChild('VRUtility'))

local VRBridge = VRUtility.RNet.Create('VRBridge')

local CurrentCamera = workspace.CurrentCamera

local REMOTE_COMMANDS = {
	VRDataClean = 0, -- cleanup the player's vr data on the server
	VREnabled = 1, -- when vr is toggled on/off
	UserCFrameState = 2, -- when a user-enum updates
	UserCFrameUpdate = 3, -- when a user-enum is toggled on/off
	CameraCFrameUpdate = 4, -- when the client's camera updates
	InputBegan = 5, -- when a input begins
	InputEnded = 6, -- when a input ends
	NavigationRequested = 7, -- when navigation is requested
}

local function InputObjectToTable( inputObject : InputObject )
	return {
		KeyCode = inputObject.KeyCode,
		UserInputState = inputObject.UserInputState,
		UserInputType = inputObject.UserInputType,
		Position = inputObject.Position,
		-- Delta = inputObject.Delta,
	}
end

-- // Module // --
local Module = {}

Module.EventCallbacks = VRUtility.Maid.New()
Module.Events = {
	VREnabled = VRUtility.Event.New(),

	CameraCFrameUpdated = VRUtility.Event.New(),
	UserCFrameEnabled = VRUtility.Event.New(),
	UserCFrameUpdated = VRUtility.Event.New(),

	NavigationRequested = VRUtility.Event.New(),
	InputBegan = VRUtility.Event.New(),
	InputEnded = VRUtility.Event.New(),
	TouchpadEnabled = VRUtility.Event.New(),
}

function Module:OnEvent( eventName : string, ... )
	local eventInstance = Module.Events[eventName]
	assert( eventInstance, "eventName is unavailable: " .. tostring(eventName) )

	local connections = { }

	local callbacks = { ... }
	for _, callback in ipairs( callbacks ) do
		assert( typeof(callback) == "function", "callbacks must be functions." )
		eventInstance:Connect( callback )
	end

	return connections
end

function Module:FireEvent( eventName : string, ... )
	local eventInstance = Module.Events[eventName]
	assert( eventInstance, "eventName is unavailable: " .. tostring(eventName) )

	eventInstance:Fire(...)
end

if RunService:IsServer() then

	function Module:CleanupVRData( LocalPlayer )

	end

	function Module:CleanupEventCallbacks()
		Module.EventCallbacks:Cleanup()
	end

	function Module:SetupEventCallbacks()

	end

	function Module:Init()

		Players.PlayerRemoving:Connect(function(LocalPlayer)
			Module:CleanupVRData( LocalPlayer )
		end)

		VRBridge:OnServerEvent(function(LocalPlayer : Player, ...)
			local Args = {...}
			local Command = table.remove(Args, 1)
			print(LocalPlayer.Name, Command, Args)
		end)

	end

	function Module:Start()

	end

	function Module:Stop()

	end

else

	local LocalPlayer = Players.LocalPlayer

	local PlayerModule = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
	local PlayerControls = PlayerModule:GetControls()

	function Module:CleanupEventCallbacks()
		Module.EventCallbacks:Cleanup()
	end

	function Module:SetupEventCallbacks()

		Module:CleanupEventCallbacks() -- force cleanup before-hand

		Module.EventCallbacks:Give(
			VRService:GetPropertyChangedSignal('VREnabled'):Connect(function()
				Module:FireEvent('VREnabled', VRService.VREnabled )
			end),

			VRService.NavigationRequested:Connect(function(value : CFrame, inputUserCFrame : Enum.UserCFrame)
				Module:FireEvent('NavigationRequested', value, inputUserCFrame)
			end),

			VRService.TouchpadModeChanged:Connect(function(touchpad : Enum.VRTouchpad, mode : Enum.VRTouchpadMode)
				Module:FireEvent('TouchpadEnabled', touchpad, mode)
			end),

			VRService.UserCFrameEnabled:Connect(function(userCFrame : Enum.UserCFrame, isEnabled : boolean)
				Module:FireEvent('UserCFrameEnabled', userCFrame, isEnabled)
			end),

			VRService.UserCFrameChanged:Connect(function(userCFrame : Enum.UserCFrame, value : CFrame)
				Module:FireEvent('UserCFrameChanged', userCFrame, value)
			end),

			UserInputService.InputBegan:Connect(function(inputObject : InputObject, wasProcessed : boolean)
				if not wasProcessed then
					local data = InputObjectToTable( inputObject )
					Module:FireEvent('InputBegan', data)
				end
			end),

			UserInputService.InputEnded:Connect(function(inputObject : InputObject, wasProcessed : boolean)
				if not wasProcessed then
					local data = InputObjectToTable( inputObject )
					Module:FireEvent('InputEnded', data)
				end
			end)
		)

		Module.EventCallbacks:Give(function()
			VRBridge:FireServer(REMOTE_COMMANDS.VRDataClean)
		end)

	end

	function Module:Init()

		VRBridge:OnClientEvent(function(...)
			local Args = {...}
			local Command = table.remove(Args, 1)
			print(Command, Args)
		end)

	end

	function Module:Start()

		Module:SetupEventCallbacks()

	end

	function Module:Stop()

		Module:CleanupEventCallbacks()

	end

end

return Module
