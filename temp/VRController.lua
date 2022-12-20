-- SPOOK_EXE
-- Manages all vr controls and provides an optional template VR Environment.

local RunService = game:GetService('RunService')
if RunService:IsServer() then
	warn('HandClass is intended for clients only. Returning empty table.')
	return {}
end

local UserInputService = game:GetService('UserInputService')
local VRService = game:GetService('VRService')
local StarterGui = game:GetService('StarterGui')

local VRSetupFolder = script.Parent
local VRAssets = VRSetupFolder:WaitForChild('Assets')
local ClassesFolder = VRSetupFolder:WaitForChild('Classes')
local VRHand_Class = require(ClassesFolder:WaitForChild('VRHand_Class'), 3) -- example environment
local VRHead_Class = require(ClassesFolder:WaitForChild('VRHead_Class'), 3) -- example environment
local ModulesFolder = VRSetupFolder:WaitForChild('Modules')
local Event = require(ModulesFolder:WaitForChild('Event'))
local Utility = require(ModulesFolder:WaitForChild('Utility'), 3) -- example environment

local DebugMode = true

--[[

	If you want it to load the default environemt do 
	
	" Module.New(true) "
	
	in a local script and it will set it all up :)
	
]]

local Module = {}

function Module.New(SetupCodedEnvironement)
	
	local self = {}
	
	warn('VR_Controller Connected')
	
	self.VRActive = VRService.VREnabled
	self.HasDeviceEnabled = VRService:GetUserCFrameEnabled(Enum.UserCFrame.Head)
	self.PrebuildActive = false
	
	self.Events = {
		InputBegan = Event.new(),
		InputChanged = Event.new(),
		InputEnded = Event.new()
	}
	
	self.Trash = {}
	self.ActiveKeybinds = {}
	self.ActiveInputTypes = {}
	
	UserInputService.InputBegan:Connect(function(InputObject, IsProcessed)
		self.ActiveKeybinds[InputObject.KeyCode] = true
		self.ActiveInputTypes[InputObject.UserInputType] = true
		self.Events.InputBegan:Fire(InputObject, IsProcessed)
	end)
	
	UserInputService.InputChanged:Connect(function(InputObject, IsProcessed)
		self.Events.InputChanged:Fire(InputObject, IsProcessed)
	end)
	
	UserInputService.InputEnded:Connect(function(InputObject, IsProcessed)
		self.ActiveKeybinds[InputObject.KeyCode] = nil
		self.ActiveInputTypes[InputObject.UserInputType] = nil
		self.Events.InputEnded:Fire(InputObject, IsProcessed)
	end)
	
	self.Trash[#self.Trash + 1] = RunService.RenderStepped:Connect(function()
		self.VRActive = VRService.VREnabled
		self.HasDeviceEnabled = VRService:GetUserCFrameEnabled(Enum.UserCFrame.Head)
	end)
	
	if SetupCodedEnvironement then
		
		warn('Setting Up Template VR Environment')
		
		self.Camera = workspace.CurrentCamera
		self.Camera.CameraType = Enum.CameraType.Scriptable
		self.LocalPlayer = game:GetService('Players').LocalPlayer
		self.PrebuildActive = true
		
		self.VR_Objects = workspace:WaitForChild('VR_Objects', 2)
		if not self.VR_Objects then
			warn('No VR Objects are present in workspace : workspace.VR_Objects')
		end
		
		local RunService = game:GetService('RunService')
		
		self.CentreBlock = VRAssets.Centre:Clone()
		self.CentreBlock.Parent = workspace
		
		self.CameraMode = 'FirstPerson'
		
		self.HeadClass = VRHead_Class.New({
			VR_OriginPart = self.CentreBlock,
		}, {})
		
		self.LeftHandModel = VRAssets.LeftVRHand:Clone()
		self.LeftHandModel.Parent = workspace
		self.LeftHandClass = VRHand_Class.New({
			VR_OriginPart = self.Camera, --self.CentreBlock,
			VR_HandEnum = Enum.UserCFrame.LeftHand,
			HandModel = self.LeftHandModel,
			VRHandOffset = CFrame.new(0, 0, -self.LeftHandModel.PrimaryPart.Size.Z/2),
			VRHandRotation = CFrame.Angles(math.pi, 0, math.pi),                          		-- UNIQUE
			HandPrimaryPart = self.LeftHandModel.PrimaryPart,
			HandAnimationController = self.LeftHandModel:FindFirstChildOfClass("AnimationController"),
			HandGrabAnimation = VRAssets.LeftHandGrabAnim
		}, {})
		
		print('Right Class')
		self.RightHandModel = VRAssets.RightVRHand:Clone()
		self.RightHandModel.Parent = workspace
		self.RightHandClass = VRHand_Class.New({
			VR_OriginPart = self.Camera, --self.CentreBlock,
			VR_HandEnum = Enum.UserCFrame.RightHand,
			HandModel = self.RightHandModel,
			VRHandObjectOffset = CFrame.new(0, 0, -self.RightHandModel.PrimaryPart.Size.Z/2),
			HandPrimaryPart = self.RightHandModel.PrimaryPart,
			HandAnimationController = self.RightHandModel:FindFirstChildOfClass("AnimationController"),
			HandGrabAnimation = VRAssets.RightHandGrabAnim
		}, {})
		
		if DebugMode then
			print(string.rep('\n', 5))
			
			print(self.HeadClass)
			print(self.LeftHandClass)
			print(self.RightHandClass)
		end
		
		self.Events.InputBegan:Connect(function(InputObject)
			if InputObject.KeyCode == Enum.KeyCode.ButtonA then
				self.HeadClass:ToggleDebug()
				self.LeftHandClass:ToggleDebug(1)
				self.RightHandClass:ToggleDebug(1)
			elseif InputObject.KeyCode == Enum.KeyCode.ButtonB then
				self.LeftHandClass:ToggleDebug(2)
				self.RightHandClass:ToggleDebug(2)
			elseif InputObject.KeyCode == Enum.KeyCode.ButtonY then
				self.LeftHandClass:ToggleDebug(3)
				self.RightHandClass:ToggleDebug(3)
			end
			if self.VR_Objects and InputObject.UserInputType == Enum.UserInputType.Gamepad1 then
				if InputObject.KeyCode == Enum.KeyCode.ButtonL1 then
					if DebugMode then
						print('Left Grab')
					end
					local Nearest = Utility:FindClosestGrabbable(self.VR_Objects:GetChildren(), self.LeftHandClass.VRHandObjectCFrame.Position)
					if Nearest then
						self.LeftHandClass:ActivateGrab(Nearest)
					end	
				elseif InputObject.KeyCode == Enum.KeyCode.ButtonR1 then
					if DebugMode then
						print('Right Grab')
					end
					local Nearest = Utility:FindClosestGrabbable(self.VR_Objects:GetChildren(), self.RightHandClass.VRHandObjectCFrame.Position)
					if Nearest then
						self.RightHandClass:ActivateGrab(Nearest)
					end	
				end
			end
		end)
		
		self.Events.InputEnded:Connect(function(InputObject)
			if InputObject.KeyCode == Enum.KeyCode.ButtonL1 then
				if DebugMode then
					print('Release Left Grab')
				end
				self.LeftHandClass:ActivateGrab(nil)
			elseif InputObject.KeyCode == Enum.KeyCode.ButtonR1 then
				if DebugMode then
					print('Release Right Grab')
				end
				self.RightHandClass:ActivateGrab(nil)
			end
		end)
		
		self.HeadClass:ToggleDebug(false)
		self.LeftHandClass:ToggleDebug(1, false)
		self.RightHandClass:ToggleDebug(1, false)
		
		RunService.RenderStepped:Connect(function()
			self:Update()
		end)
		
		StarterGui:SetCore("VRLaserPointerMode", 0)
		StarterGui:SetCore("VREnableControllerModels", false)
		
	end
	
	setmetatable(self, {__index = Module})
	
	return self
	
end

function Module:Update()
	self.VRActive = VRService.VREnabled
	self.HasDeviceEnabled = VRService:GetUserCFrameEnabled(Enum.UserCFrame.Head)
	if self.PrebuildActive and self.HeadClass then
		local Origin
		if self.CameraMode == 'FirstPerson' then
			local yValue = (2 + self.HeadClass.ActualHeadCFrame.Position.Y)
			yValue = yValue > 3 and 3 or yValue
			local origCF = self.CentreBlock.CFrame * CFrame.new(0, yValue, 0)
			self.Camera.CFrame = origCF
			Origin = origCF
		elseif self.CameraMode  == 'ViewCharacter' then
			self.CentreBlock.CFrame = CFrame.new(0, 3, 0)
			self.Camera.CFrame = CFrame.new(Origin.Position + Vector3.new(0, 5, 5), Vector3.new())
			self.CentreBlock.CFrame = CFrame.new(self.CentreBlock.CFrame.Position, self.CentreBlock.CFrame.Position + self.HeadClass.VR_HeadCFrame.LookVector)
		end
		if Origin then
			
			-- Utility:VisualAttachment()

			--[[
				VisualAttachment('HLV', Origin * (VRHeadCFrame.LookVector * 5), Color3.fromRGB(255,255,0))
				VisualAttachment('HLV-', Origin * (VRHeadCFrame.LookVector * -5))
				VisualAttachment('HRV', Origin * (VRHeadCFrame.RightVector * 5))
				VisualAttachment('HRV-', Origin * (VRHeadCFrame.RightVector * -5))
				
				local leftHandAttachment = VisualAttachment('LH', VROriginCFrame * VRLeftHandCFrame)
				local rightHandAttachment = VisualAttachment('RH', VROriginCFrame * VRRightHandCFrame)
				local headAttachment = VisualAttachment('H', VROriginCFrame * VRHeadCFrame)
			]]
			
		end
	end
end

function Module:Destroy()
	warn('VR_Controller Disconnected')
	for _,e in pairs(self.Events) do
		e:Disconnect()
	end
	self.Events = {}
	for _,e in pairs(self.Trash) do
		e:Disconnect()
	end
	self.Trash = {}
end

return Module
