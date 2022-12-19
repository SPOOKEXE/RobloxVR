local RunService = game:GetService('RunService')

local VRModule = nil

-- // Module // --
local Module = {}

function Module:Init(MainVRModule)
	VRModule = MainVRModule
	-- initialize here
end

if RunService:IsServer() then



else

	function Module:Enable()
		print(script.Name, 'Enabled')
	end

	function Module:Disable()
		print(script.Name, 'Disabled')
	end

end

return Module
