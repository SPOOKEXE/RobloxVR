local RunService = game:GetService('RunService')

local Threader = require(script.Parent.Threader) :: ((...any?) -> nil)
local Networker = require(script.Parent.Network)

local IS_SERVER = RunService:IsServer()

export type Packet = {
	Type : number,
	Args : {any?},
	TimeoutTick : number?,
	Target : Player?,
}

export type ServerBridge = {
	_id  : string,
	_queue : { Packet },

	_eventHandlers : { (...any?) -> nil }, -- when bridge is Fired
	_invokeHandlers : { (...any?) -> any? }, -- when bridge is Invoked
	_priorityNumbers : { number },

	_event : RemoteEvent,
	_function : RemoteFunction,

	FireClient : (...any?) -> nil,
	FireAllClients : (...any?) -> nil,
	InvokeClient : (...any?) -> any?,

	OnServerEvent : ((...any?) -> nil, number?) -> nil,
	OnServerInvoke : ((...any?) -> any?, number?) -> nil,
}

export type ClientBridge = {
	_id  : string,
	_queue : { Packet },

	_eventHandlers : { (...any?) -> nil }, -- when bridge is Fired
	_invokeHandlers : { (...any?) -> any? }, -- when bridge is Invoked
	_priorityNumbers : { number },

	_event : RemoteEvent,
	_function : RemoteFunction,

	FireServer : (...any?) -> nil,
	InvokeServer : (...any?) -> any?,

	OnClientEvent : ((...any?) -> nil, number?) -> nil,
	OnClientInvoke : ((...any?) -> any?, number?) -> nil,
}

-- // Networker // --
local COMMAND_TYPES = { Fire = 1 }
local DEFAULT_PACKET_LIFETIME = 5 -- how long do packets stay in queue before being deleted
local PACKETS_PER_HEARTBEAT = 5
local ACTIVE_BRIDGES = {}

-- // Bridge Utilities // --
local function returnFalse()
	return false
end

local function SortBridgeNumbers( bridge )
	table.sort(bridge._priorityNumbers, function(a, b)
		return a > b
	end)
end

local function BRIDGE_EVENT_CALLBACK_PASS( bridge, callback : (...any?) -> any?, priority : number? )
	priority = priority or 0
	if not table.find(bridge._priorityNumbers, priority) then
		table.insert(bridge._priorityNumbers, priority)
		SortBridgeNumbers( bridge )
	end

	if not bridge._eventHandlers[priority] then
		bridge._eventHandlers[priority] = { }
	end

	local priorityDict = bridge._eventHandlers[priority]
	local existantIndex = table.find( priorityDict, callback )
	if existantIndex then
		table.remove(priorityDict, existantIndex)
	end

	table.insert(priorityDict, 1, callback)
end

local function BRIDGE_INVOKE_CALLBACK_PASS( bridge, callback : (...any?) -> any?, priority : number? )
	priority = priority or 0
	if not table.find(bridge._priorityNumbers, priority) then
		table.insert(bridge._priorityNumbers, priority)
		SortBridgeNumbers( bridge )
	end

	if not bridge._invokeHandlers[priority] then
		bridge._invokeHandlers[priority] = { }
	end

	local priorityDict = bridge._invokeHandlers[priority]
	local existantIndex = table.find( priorityDict, callback )
	if existantIndex then
		table.remove(priorityDict, existantIndex)
	end

	table.insert(priorityDict, 1, callback)
end

local function CreateRemotePair( bridgeName : string ) : (RemoteEvent, RemoteFunction)
	local Event = script:FindFirstChild(bridgeName..'_Event')
	local Func = script:FindFirstChild(bridgeName..'_Function')
	if Event and Func then
		return Event, Func
	end

	if IS_SERVER then
		-- if server, create remotes that are missing
		if not Event then
			Event = Instance.new('RemoteEvent')
			Event.Name = bridgeName..'_Event'
			Event.Parent = script
		end
		if not Func then
			Func = Instance.new('RemoteFunction')
			Func.Name = bridgeName..'_Function'
			Func.Parent = script
		end
	else
		-- if client, wait for remotes
		Event = script:WaitForChild(bridgeName..'_Event')
		Func = script:WaitForChild(bridgeName..'_Function')
	end

	return Event, Func
end

local function SetupMiddleware( bridge )

	-- TODO: use a different method that iterates over all bridges
	Networker:ReceiveEvent(bridge._event, function(LocalPlayer : Player, ... : any?)
		for _, priorityNumber in ipairs( bridge._priorityNumbers ) do
			if not bridge._eventHandlers[priorityNumber] then
				continue
			end
			for _, callback in ipairs( bridge._eventHandlers[priorityNumber] ) do
				Threader(callback, LocalPlayer, ...)
			end
		end
	end)

	Networker:ReceiveInvoke(bridge._function, function(LocalPlayer : Player, ... : any?)
		for _, priorityNumber in ipairs( bridge._priorityNumbers ) do
			if not bridge._invokeHandlers[priorityNumber] then
				continue
			end
			for _, callback in ipairs( bridge._invokeHandlers[priorityNumber] ) do
				local values = { callback(LocalPlayer, ...) }
				if #values == 0 then
					continue
				end
				return unpack(values)
			end
		end
		return nil
	end)

end

-- // Client Bridge // --
local ClientBridge = { ClassName = "ClientBridge" }
ClientBridge.__index = ClientBridge

function ClientBridge.Create(bridgeName)
	local bridgeEvent, bridgeFunction = CreateRemotePair( bridgeName )
	local self = setmetatable({
		_id = bridgeName,
		_queue = { },

		_eventHandlers = { }, -- when bridge is Fired
		_invokeHandlers = { returnFalse }, -- when bridge is Invoked
		_priorityNumbers = { },

		_event = bridgeEvent,
		_function = bridgeFunction,
	}, ClientBridge)
	SetupMiddleware( self )
	table.insert(ACTIVE_BRIDGES, self)
	return self
end

function ClientBridge:FireServer( ... : any? )
	table.insert(self._queue, {
		Type=COMMAND_TYPES.Fire,
		Args={...},
		TimeoutTick=tick() + DEFAULT_PACKET_LIFETIME,
	})
end

function ClientBridge:InvokeServer( ... : any? )
	return Networker:Invoke( self._function, ... )
end

function ClientBridge:OnClientEvent(callback : (...any?) -> nil, priority : number?)
	return BRIDGE_EVENT_CALLBACK_PASS( self, callback, priority )
end

function ClientBridge:OnClientInvoke(callback : (...any?) -> any?, priority : number?)
	return BRIDGE_INVOKE_CALLBACK_PASS( self, callback, priority )
end

-- // Server Bridge // --
local ServerBridge = { ClassName = "ServerBridge" }
ServerBridge.__index = ServerBridge

function ServerBridge.Create(bridgeName)
	local bridgeEvent, bridgeFunction = CreateRemotePair( bridgeName )
	local self = setmetatable({
		_id = bridgeName,
		_queue = { },

		_eventHandlers = { }, -- when bridge is Fired
		_invokeHandlers = { returnFalse }, -- when bridge is Invoked
		_priorityNumbers = { },

		_event = bridgeEvent,
		_function = bridgeFunction,
	}, ServerBridge)
	SetupMiddleware(self)
	table.insert(ACTIVE_BRIDGES, self)
	return self
end

function ServerBridge:FireClient( LocalPlayer : Player, ... : any? )
	table.insert(self._queue, {
		Target=LocalPlayer,
		Type=COMMAND_TYPES.Fire,
		Args={...},
		TimeoutTick=tick() + DEFAULT_PACKET_LIFETIME,
	})
end

function ServerBridge:FireAllClients(... : any?)
	table.insert(self._queue, {
		Type=COMMAND_TYPES.Fire,
		Args={...},
		TimeoutTick=tick() + DEFAULT_PACKET_LIFETIME,
	})
end

function ServerBridge:InvokeClient( LocalPlayer : Player, ... : any? )
	return Networker:InvokeClient( self._function, LocalPlayer, ... )
end

function ServerBridge:OnServerEvent(callback : (...any?) -> any?, priority : number?)
	return BRIDGE_EVENT_CALLBACK_PASS( self, callback, priority )
end

function ServerBridge:OnServerInvoke(callback : (...any?) -> any?, priority : number?)
	return BRIDGE_INVOKE_CALLBACK_PASS( self, callback, priority )
end

-- // Module // --
local Module = {}

local BridgeCache = { }

function Module.Create( bridgeName : string )
	if BridgeCache[bridgeName] then
		return BridgeCache[bridgeName]
	end
	local Bridge = nil
	if IS_SERVER then
		Bridge = ServerBridge.Create(bridgeName)
	else
		Bridge = ClientBridge.Create(bridgeName)
	end
	BridgeCache[bridgeName] = Bridge
	return Bridge
end

local function UpdateBridgeTraffic( bridge )
	local packet = table.remove(bridge._queue, 1)

	if IS_SERVER then -- server-side
		if packet.Type == COMMAND_TYPES.Fire then
			if packet.Target then
				Networker:Fire( bridge._event, packet.Target, packet.Args )
			else
				Networker:FireAll( bridge._event, packet.Args )
			end
		end
	else -- client-side
		if packet.Target then
			error("Invalid packet - cannot specify a target.")
		end
		if packet.Type == COMMAND_TYPES.Fire then
			Networker:Fire( bridge._event, packet.Args )
		end
	end

end

RunService.Heartbeat:Connect(function()
	local now = tick()
	for _, bridge in ipairs( ACTIVE_BRIDGES ) do
		-- clear dropped packets
		local index = 1
		while index <= #bridge._queue do
			local packet = bridge._queue[ index ]
			if now > packet.TimeoutTick then
				table.remove(bridge._queue, index) -- drop FIRE packets
			else
				index += 1
			end
		end
		-- update traffic
		if #bridge._queue == 0 then
			continue
		end

		for _ = 1, math.min( #bridge._queue, PACKETS_PER_HEARTBEAT ) do
			UpdateBridgeTraffic( bridge )
		end
	end
end)

return Module
