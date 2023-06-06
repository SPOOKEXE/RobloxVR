
-- // Segment // --
local Segment = {}
Segment.__index = Segment

function Segment.New(pos, length_, angle_)
	local self = setmetatable({
		a = pos, b = false,
		angle = angle_, length = length_,
		parent = false, child = false,
	}, Segment)
	self:calculate_b()
	return self
end

function Segment:calculate_b()
	local dx = self.length * math.cos(self.angle)
	local dy = self.length * math.sin(self.angle)
	self.b = Vector2.new( self.a.x + dx, self.a.y + dy )
	return self
end

function Segment:setA(position2d)
	self.a = position2d
end

function Segment:follow_target(tx, ty)
	local _dir = Vector2.new( tx - self.a.x, ty - self.a.y )
	local _angle = math.atan2( _dir.y, _dir.x )
	self.angle = _angle
	_dir = _dir.Unit * -self.length
	self.a = Vector2.new( tx + _dir.x, ty + _dir.y )
	return self
end

function Segment:follow_segment(segment)
	self:follow_target( segment.a.x, segment.a.y )
end

function Segment:update()
	self:calculate_b()
	return self
end

-- // Tentacle // --
local Tentacle = {}
Tentacle.__index = Tentacle

function Tentacle.New(total_segments : number, segment_length : {number} | number)
	local self = setmetatable({
		segments = {},
		total_segments = total_segments,
		base_vector = false
	}, Tentacle)

	-- if its a number, convert to a table
	if typeof(segment_length) == "number" then
		segment_length = { segment_length }
	end

	assert( typeof(segment_length) == "table", "Segment Length must be either a table or a number." )

	local baseSegment = Segment.New(Vector2.new(), segment_length[1], 1)
	for idx = 1, total_segments do
		local seg_next = Segment.New(baseSegment.b, segment_length[ math.min(idx, #segment_length) ], 1)
		seg_next.parent = baseSegment
		baseSegment.child = seg_next
		table.insert(self.segments, 1, seg_next)
		baseSegment = seg_next
	end

	return self
end

function Tentacle.fromSegments( segmentArray, segment_length )
	local total_segments = #segmentArray

	local self = setmetatable({
		segments = {},
		total_segments = total_segments,
		base_vector = false
	}, Tentacle)
	
	local baseSegment = table.remove(segmentArray, 1)
	for idx, seg_next in ipairs( segmentArray ) do
		seg_next.a = baseSegment.b
		seg_next.parent = baseSegment
		baseSegment.child = seg_next
		table.insert(self.segments, 1, seg_next)
		baseSegment = seg_next
	end

	return self
end

function Tentacle:setBase(position)
	self.base_vector = position
end

function Tentacle:getAngles()
	local anglez = {}
	for _, segment in ipairs(self.segments) do
		table.insert(anglez, segment.angle)
	end
	return anglez
end

function Tentacle:setAngles(angles)
	for index, seg in ipairs(self.segments) do
		seg.angle = angles[index]
	end
	for _, seg in ipairs(self.segments) do
		seg:update()
	end
end

function Tentacle:shift_segments()
	self.segments[1]:calculate_b()
	for i = 2, #self.segments do
		self.segments[i]:setA( self.segments[i-1].b )
		self.segments[i]:calculate_b()
	end
end

function Tentacle:follow(tx, ty)
	local length = #self.segments

	local endd = self.segments[length]
	endd:follow_target(tx, ty)
	endd:update()
	for i = length-1, 1, -1 do
		self.segments[i]:follow_segment(self.segments[i+1])
		self.segments[i]:update()
	end

	-- check if there is a base vector
	if self.base_vector == nil then
		return
	end

	self.segments[1]:setA(self.base_vector)
	self:shift_segments()
end

-- // Module // --
local Module = {}

Module.Segment = Segment
Module.Tentacle = Tentacle

return Module
