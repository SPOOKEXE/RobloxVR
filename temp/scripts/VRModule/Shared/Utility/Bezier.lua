
local function Llerp(a, b, c)
	return a + (b - a) * c
end

-- // Module // --
local Module = {}

function Module.GetQuadBezierNumber(p0, p1, p2, alpha)
	local l1 = Llerp(p0, p1, alpha)
	local l2 = Llerp(p1, p2, alpha)
	return Llerp(l1, l2, alpha)
end

function Module.GetQuadBezierVector(p0, p1, p2, alpha)
	local l1 = p0:Lerp(p1, alpha)
	local l2 = p1:Lerp(p2, alpha)
	return l1:Lerp(l2, alpha)
end

function Module.GetCubicBezierNumber(a, b, c, d, alpha)
	return
		math.pow( 1 - alpha, 3 ) * a +
		3 * math.pow(1 - alpha, 2) * alpha * b +
		3 * (1 - alpha) * math.pow(alpha, 2) * c +
		math.pow(alpha, 3) * d
end

function Module.GetCubicBezierVector(p1, p2, p3, p4, alpha)
	return Vector3.new(
		Module.GetCubicBezierNumber(p1.X, p2.X, p3.X, p4.X, alpha),
		Module.GetCubicBezierNumber(p1.Y, p2.Y, p3.Y, p4.Y, alpha),
		Module.GetCubicBezierNumber(p1.Z, p2.Z, p3.Z, p4.Z, alpha)
	)
end

return Module
