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

	
	
	EXAMPLE "PropertyTable" FOR CLASS
	--------------------------------
	{
		VR_OriginPart = HumanoidRootPart
	}
	
	
	
	EXAMPLE "ConfigTable" TABLE FOR CLASS
	--------------------------------
	{
		NoAutoUpdate = nil
	}
	
]]

local Module = {}

local Module = {}

function Module.New(PropertyTable, ConfigTable)

	local self = {}

	self.HandActive = VRService.VREnabled

	warn('VR Hand Class', self.HandActive and 'Enabled' or 'Disabled')
	
	-- Values
	self.MoveCamera = true
	self.CameraMode = 'FirstPerson'
	
	-- Data recieved from VR Headset
	self.CentreBlock = nil
	self.VR_OriginCFrame = CFrame.new()
	self.VR_HeadEnum = Enum.UserCFrame.Head
	self.VR_HeadCFrame = VRService:GetUserCFrame(self.VR_HeadEnum)
	
	self.ActualHeadCFrame = self.VR_OriginCFrame * self.VR_HeadCFrame
	
	-- Debug Values
	self.ShowAttachments = false
	self.DebugAttachments = {} -- CREATE THE ATTACHMENTS HERE
	
	-- Debug Prints
	if DebugMode then
		warn(PropertyTable, ConfigTable)
		if typeof(ConfigTable) == 'table' then
			print('Auto Update: ', ConfigTable.AutoUpdate and 'Enabled' or 'Disabled')
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
	
	-- Config Table
	ConfigTable = ConfigTable or {}
	if typeof(ConfigTable) == 'table' then
		if not ConfigTable.NoAutoUpdate then
			RunService.RenderStepped:Connect(function()
				self:Update()
			end)
		end
	elseif ConfigTable ~= nil and not DebugMode then
		warn('Given Config Table is not a table! ', ConfigTable)
	end

	setmetatable(self, {__index = Module})

	return self

end

function Module:Update()
	self.HeadActive = VRService.VREnabled and VRService:GetUserCFrameEnabled(self.VR_HeadEnum)
	self.VR_HeadCFrame = VRService:GetUserCFrame(self.VR_HeadEnum)
	self.VR_OriginCFrame = self.CentreBlock and self.CentreBlock.CFrame or CFrame.new()
	self.ActualHeadCFrame = self.VR_OriginCFrame * self.VR_HeadCFrame
	if self.HeadActive then
		self.HasWarnedAboutDisabledHead = false
		
		if self.VR_OriginPart then
			local Origin
			if self.CameraMode == 'FirstPerson' then
				local yValue = (2 + self.ActualHeadCFrame.Position.Y)
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
	            --VisualAttachment('HLV', Origin * (VRHeadCFrame.LookVector * 5), Color3.fromRGB(255,255,0))
	            --VisualAttachment('HLV-', Origin * (VRHeadCFrame.LookVector * -5))
	            --VisualAttachment('HRV', Origin * (VRHeadCFrame.RightVector * 5))
	            --VisualAttachment('HRV-', Origin * (VRHeadCFrame.RightVector * -5))
	            --local leftHandAttachment = VisualAttachment('LH', VROriginCFrame * VRLeftHandCFrame)
	            --local rightHandAttachment = VisualAttachment('RH', VROriginCFrame * VRRightHandCFrame)
	            --local headAttachment = VisualAttachment('H', VROriginCFrame * VRHeadCFrame)
			end
		end
	elseif not self.HasWarnedAboutDisabledHead then
		self.HasWarnedAboutDisabledHead = true
		warn('VR-Head has been disabled! ', self.HandModel and self.HandModel:GetFullName() or 'No Hand Model!')
	end
end

function Module:ToggleDebug(Force)
	self.ShowAttachments = (Force == nil) and (not self.ShowAttachments) or Force
	for _,Attachment in pairs(self.DebugAttachments) do
		if Attachment:IsA('BasePart') then
			Attachment.Transparency = self.ShowAttachments and 0.5 or 1
		elseif Attachment:IsA('Attachment') then
			Attachment.Visible = self.ShowAttachments
		end
	end
end

return Module
