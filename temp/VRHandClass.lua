-- SPOOK_EXE

local RunService = game:GetService('RunService')
if RunService:IsServer() then
	warn('HandClass is intended for clients only. Returning empty table.')
	return {}
end

local VRService = game:GetService('VRService')
local UtilityModule = require(script.Parent.Parent.Modules.Utility)

local DebugMode = true

--[[

	
	EXAMPLE "PropertyTable" & "ConfigTable" FOR CLASS
	--------------------------------
	
	local Hand = LeftHand:Clone()
	
	-- property table
	{
		VR_OriginPart = HumanoidRootPart
		VR_HandEnum = Enum.UserCFrame.LeftHand
		HandModel = Hand,
		HandPrimaryPart = Hand.PrimaryPart,
		HandAnimationController = Hand:FindFirstChildOfClass("AnimationController"),
		HandGrabAnimation = Hand.LeftHandGrabAnimation
	},
	
	-- config table
	{ 
		NoAutoUpdate = nil,
		AnimationsLoadedElsewhere = nil -- if you intend to load the grab animation outside the script
	}






	EXAMPLE "ExtraArguments" FOR GRAB FUNCTION
	-----------------------------------------
	
	TargetObject,
	{
		GrabbedOffset = CFrame.new()
		GrabbedRotation = CFrame.Angles(0,0,0)
	}


]]

local Module = {}

function Module.New(PropertyTable, ConfigTable)
	
	local self = setmetatable({}, {__index = Module})

	self.HandActive = VRService.VREnabled
	
	warn('VR Hand Class', self.HandActive and 'Enabled' or 'Disabled')
	
	-- Data recieved from VR Headset
	self.VR_OriginPart = nil
	self.VR_OriginCFrame = CFrame.new()
	self.VR_HandEnum = Enum.UserCFrame.LeftHand
	self.VR_HandCFrame = VRService:GetUserCFrame(self.VR_HandEnum)

	-- Actual Hand Model
	self.VRHandOffset = CFrame.new()
	self.VRHandRotation = CFrame.Angles(0,0,0)  
	self.VRHandObjectCFrame = (self.VR_OriginCFrame * self.VR_HandCFrame * self.VRHandOffset * self.VRHandRotation)
	self.HandModel = nil
	self.HandPrimaryPart = nil
	self.HandAnimationController = nil
	self.HandGrabAnimation = nil
	self.LoadedGrabAnimation = nil
	
	-- Grabbed Model Offset (pass through the grab function)
	self.VRHandObjectOffset = CFrame.new() -- CFrame.new(0, 0, -VRHand.PrimaryPart.Size.Z/2)
	self.VRHandObjectRotation = CFrame.Angles(0,0,0) -- LeftHand >> CFrame.Angles(math.pi, 0, math.pi)

	-- Grabbing Values
	self.Grabbing = false
	self.GrabbedObject = nil
	self.GrabbedOffset = CFrame.new()
	self.GrabbedRotation = CFrame.Angles(0,0,0)
	self.GrabbedObjectCFrame = self.GrabbedOffset * self.GrabbedRotation
	
	-- Debug Values
	self.ShowAttachments = false
	self.DebugAttachments = {}
	self.ShowBones = false
	self.DebugBones = {}
	self.ShowBoneStructure = false
	self.DebugBoneBeams = {}
	
	-- Debug Prints
	if DebugMode then
		warn(PropertyTable, ConfigTable)
		if typeof(ConfigTable) == 'table' then
			print('Auto Update: ', ConfigTable.AutoUpdate and 'Enabled' or 'Disabled')
			print('Loading Scripts In: ', ConfigTable.AnimationsLoadedElsewher and 'Other Script' or 'This Class')
		end
	end
	
	-- Properties
	if typeof(PropertyTable) == 'table' then
		for propertyName, propertyValue in pairs(PropertyTable) do
			self[propertyName] = propertyValue
		end
	elseif not DebugMode then
		warn('Property Table is not a table! ', PropertyTable)
	end
	if self.HandModel then
		for _,Descendant in pairs(self.HandModel:GetDescendants()) do
			if Descendant:IsA('Attachment') then
				table.insert(self.DebugAttachments, Descendant)
			elseif Descendant.Name == 'Attachment' and Descendant:IsA('BasePart') then
				table.insert(self.DebugAttachments, Descendant)
			elseif Descendant:IsA('Bone') then
				table.insert(self.DebugBones, Descendant)
			end
		end
		local boneBeams = UtilityModule.BoneVisualiser(self.HandModel)
		for i = 1, #boneBeams do
			table.insert(self.DebugBoneBeams, boneBeams[i])
		end
	end
	
	-- Config Table
	if typeof(ConfigTable) == 'table' then
		if not ConfigTable.NoAutoUpdate then
			RunService.RenderStepped:Connect(function()
				self:Update()
			end)
		end
		if not ConfigTable.AnimationsLoadedElsewhere then
			if self.HandAnimationController and self.HandGrabAnimation then
				self.LoadedGrabAnimation = self.HandAnimationController:LoadAnimation(self.HandGrabAnimation)
			end
		end
	elseif ConfigTable ~= nil and not DebugMode then
		warn('Given Config Table is not a table! ', ConfigTable)
	end
	
	return self
	
end

function Module:ActivateGrab(Object, ExtraArguments)
	
	if Object ~= nil and typeof(Object) ~= 'Instance' then
		warn('Recieved a value other than nil/Instance | ', Object)
		return nil
	end
	
	if Object == nil or self.GrabbedObject == Object then
		self.Grabbing = false
		self.GrabbedObject = nil
		if self.LoadedGrabAnimation then
			self.LoadedGrabAnimation:Stop()
		end
		if DebugMode then
			warn('Reset Grip - no object to grab')
		end
		return nil
	end
	
	self.GrabbedOffset = CFrame.new()
	self.GrabbedRotation = CFrame.Angles(0,0,0)
	
	if typeof(ExtraArguments) == 'table' then
		for k,v in pairs(ExtraArguments) do
			self[k] = v
		end
	elseif ExtraArguments ~= nil then
		warn('Extra Arguments is not a table: ', ExtraArguments)
	end
	
	self.GrabbedObject = Object
	self.GrabbedObjectCFrame = self.GrabbedOffset * self.GrabbedRotation
	self.Grabbing = true
	
	if self.LoadedGrabAnimation then
		self.LoadedGrabAnimation:Play()
	end
	
	if DebugMode then
		warn('Object Grabbed')
	end
	
end

function Module:Update()
	self.HandActive = VRService.VREnabled and VRService:GetUserCFrameEnabled(self.VR_HandEnum)
	self.VR_OriginCFrame = self.VR_OriginPart.CFrame or CFrame.new()
	self.VR_HandCFrame = VRService:GetUserCFrame(self.VR_HandEnum)
	self.VRHandObjectCFrame = (self.VR_OriginCFrame * self.VR_HandCFrame * self.VRHandOffset * self.VRHandRotation)
	if self.HandActive then
		self.HasWarnedAboutDisabledHands = false
		if self.HandModel and self.HandPrimaryPart then
			UtilityModule:SetPartOrModelCFrame(self.HandModel, self.VRHandObjectCFrame)
			-- UtilityModule:ResetVelocity(self.HandModel)
			if self.Grabbing and self.GrabbedObject then
				self.GrabbedObjectCFrame = self.VRHandObjectCFrame * self.GrabbedOffset * self.GrabbedRotation
				UtilityModule:SetPartOrModelCFrame(self.GrabbedObject, self.GrabbedObjectCFrame)
				UtilityModule:ResetVelocity(self.GrabbedObject)
			end
		end
	elseif not self.HasWarnedAboutDisabledHands then
		self.HasWarnedAboutDisabledHands = true
		warn('VR-Hand has been disabled! ', self.HandModel and self.HandModel:GetFullName() or 'No Hand Model!')
	end
end

function Module:ToggleDebug(Num, Force)
	if (Force ~= nil) then
		Num = nil
		self.ShowAttachments = Force
		self.ShowBones = Force
		self.ShowBoneStructure = Force
	end
	if Num == 1 then
		self.ShowAttachments = not self.ShowAttachments
		for _,Attachment in pairs(self.DebugAttachments) do
			if Attachment:IsA('BasePart') then
				Attachment.Transparency = self.ShowAttachments and 0.5 or 1
			elseif Attachment:IsA('Attachment') then
				Attachment.Visible = self.ShowAttachments
			end
		end
	end
	if Num == 2 then
		self.ShowBones = not self.ShowBones
		for _,Bone in pairs(self.DebugBones) do
			Bone.Visible = self.ShowBones
		end
	end
	if Num == 3 then
		self.ShowBoneStructure = not self.ShowBoneStructure
		for _,Beam in pairs(self.DebugBoneBeams) do
			Beam.Enabled = self.ShowBoneStructure
		end
	end
	if self.HandModel then
		for _,item in pairs(self.HandModel:GetDescendants()) do
			if item:IsA('BasePart') then
				item.Transparency = (self.ShowAttachments or self.ShowBones or self.ShowBoneStructure) and 0.5 or 0
			end
		end
	end
end

return Module
