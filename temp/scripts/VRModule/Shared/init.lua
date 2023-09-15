
local Module = {}

for _, ModuleScript in ipairs( script:GetChildren() ) do
	Module[ModuleScript.Name] = require(ModuleScript)
end

return Module
