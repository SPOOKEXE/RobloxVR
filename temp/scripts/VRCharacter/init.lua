local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local VRModule = nil

local Classes = require(script.Classes)
local Services = require(script.Services)

-- // Module // --
local Module = {}

function Module:Init(MainVRModule)
	VRModule = MainVRModule
	-- initialize here
end

if RunService:IsServer() then

else

	local UserInputService = game:GetService('UserInputService')

	local CurrentCamera = workspace.CurrentCamera
	local Terrain = workspace.Terrain

	local MaidInstance = Classes.Maid.New()

	local function SetupAttachmentEvent(Identification : Enum.UserCFrame, Callback : (Attachment, CFrame) -> ()) : table
		local AttachmentInstance = Instance.new('Attachment')
		AttachmentInstance.Name = Identification.Name
		AttachmentInstance.Visible = true
		AttachmentInstance.Parent = Terrain

		local Connection = VRModule:OnSignalEvent('UserCFrameChanged', function(Identifier, CFValue)
			if Identification == Identifier then
				Callback(AttachmentInstance, CFValue)
			end
		end)

		MaidInstance:Give(AttachmentInstance, Connection)
	end

	function Module:Enable()
		print(script.Name, 'Enabled')

		local function AttachmentReposition(Attachment, CFrameValue)
			Attachment.CFrame = CurrentCamera.CFrame * CFrameValue
		end

		SetupAttachmentEvent(Enum.UserCFrame.LeftHand, AttachmentReposition)
		SetupAttachmentEvent(Enum.UserCFrame.RightHand, AttachmentReposition)
		SetupAttachmentEvent(Enum.UserCFrame.Floor, AttachmentReposition)

		local LocomotiveEnabled = false
		local LocomotiveDirection = Vector2.new()

		local LastRightCFrame = CFrame.new()

		MaidInstance:Give(VRModule:OnSignalEvent('UserCFrameChanged', function(UserEnum, CFValue)
			if UserEnum == Enum.UserCFrame.RightHand then
				LastRightCFrame = CFValue
			end
		end))

		local function CheckLocomotiveState()
			if LocomotiveEnabled then
				return
			end

			LocomotiveEnabled = true
			while LocomotiveEnabled do
				local LookVector = (CurrentCamera.CFrame * LastRightCFrame).LookVector
				local RightVector = (CurrentCamera.CFrame * LastRightCFrame).RightVector
				local OffsetVector = (LookVector * LocomotiveDirection.Y) + (RightVector * LocomotiveDirection.X)
				CurrentCamera.CFrame += OffsetVector
				task.wait()
			end
		end

		MaidInstance:Give(UserInputService.InputBegan:Connect(function(InputObject, wasProcessed)
			if InputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
				CheckLocomotiveState()
			end
		end))

		MaidInstance:Give(UserInputService.InputChanged:Connect(function(InputObject, wasProcessed)
			if InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
				LocomotiveDirection = Vector2.new(InputObject.Position.X, InputObject.Position.Y)
				if LocomotiveDirection.Magnitude > 0 then
					CheckLocomotiveState()
				else
					LocomotiveEnabled = false
				end
			end
		end))

		MaidInstance:Give(UserInputService.InputEnded:Connect(function(InputObject, wasProcessed)
			if InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
				LocomotiveEnabled = false
			end
		end))
	end

	function Module:Disable()
		print(script.Name, 'Disabled')

		MaidInstance:Cleanup()
	end

end

return Module
