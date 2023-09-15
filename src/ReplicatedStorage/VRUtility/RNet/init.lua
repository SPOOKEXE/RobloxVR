
local Bridges = require(script.Bridges)

export type Packet = Bridges.Packet
export type ServerBridge = Bridges.ServerBridge
export type ClientBridge = Bridges.ClientBridge

-- // Module // --
local Module = {}

function Module.Create( bridgeName : string ) : ServerBridge | ClientBridge
	return Bridges.Create(bridgeName)
end

return Module
