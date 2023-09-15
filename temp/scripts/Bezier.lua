-- Functions
local function lerp(a, b, c)
	return a + (b - a) * c
end

local function Quad(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local Quad = lerp(l1, l2, t)
	return Quad
end

function RecursiveBezier(t, ...)
	local Points = {...}
	if #Points == 3 then
		return Quad(t, ...)
	elseif #Points == 2 then
		return lerp(Points[1], Points[2], t)
	end

	local NthM1 = { }
	for index = 1, #Points - 2 do
		local p0 = Points[index]
		local p1 = Points[index+1]
		local p2 = Points[index+2]
		table.insert(NthM1, Quad(t, p0, p1, p2) )
	end
	return RecursiveBezier(t, unpack(NthM1))
end

return {
	QuadBezier = Quad,

	CubicBezier = function(t, p0, p1, p2, p3)
		local l1 = lerp(p0, p1, t)
		local l2 = lerp(p1, p2, t)
		local l3 = lerp(p2, p3, t)
		local a = lerp(l1, l2, t)
		local b = lerp(l2, l3, t)
		local cubic = lerp(a, b, t)
		return cubic
	end,

	Recursive = RecursiveBezier,
}