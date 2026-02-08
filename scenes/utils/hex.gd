@tool
class_name Hex
extends RefCounted

const DIR_NAME_TO_INDEX = {"E": 0, "NE": 1, "NW": 2, "W": 3, "SW": 4, "SE": 5}

static var hex_directions = [
	Hex.new(1, 0, -1),  # 東 (E)
	Hex.new(1, -1, 0),  # 北東 (NE)
	Hex.new(0, -1, 1),  # 北西 (NW)
	Hex.new(-1, 0, 1),  # 西 (W)
	Hex.new(-1, 1, 0),  # 南西 (SW)
	Hex.new(0, 1, -1)  # 南東 (SE)
]

static var hex_diagonals = [
	Hex.new(2, -1, -1),
	Hex.new(1, -2, 1),
	Hex.new(-1, -1, 2),
	Hex.new(-2, 1, 1),
	Hex.new(-1, 2, -1),
	Hex.new(1, 1, -2)
]

var q
var r
var s


func _init(q_val, r_val, s_val = null):
	q = q_val
	r = r_val
	if s_val == null:
		s = -q_val - r_val
	else:
		s = s_val


func is_valid() -> bool:
	return (q + r + s) == 0


func _to_string() -> String:
	return "(%s, %s, %s)" % [q, r, s]


static func add(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.q + b.q, a.r + b.r, a.s + b.s)


static func subtract(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.q - b.q, a.r - b.r, a.s - b.s)


static func scale(a: Hex, k: int) -> Hex:
	return Hex.new(a.q * k, a.r * k, a.s * k)


static func equals(a: Hex, b: Hex) -> bool:
	return a.q == b.q and a.r == b.r and a.s == b.s


static func rotate_left(a: Hex) -> Hex:
	return Hex.new(-a.s, -a.q, -a.r)


static func rotate_right(a: Hex) -> Hex:
	return Hex.new(-a.r, -a.s, -a.q)


static func direction(direction_index: int) -> Hex:
	return hex_directions[direction_index]


static func direction_by_name(name: String) -> Hex:
	if DIR_NAME_TO_INDEX.has(name):
		return direction(DIR_NAME_TO_INDEX[name])
	return null


static func neighbor(hex: Hex, direction_index: int) -> Hex:
	return add(hex, direction(direction_index))


static func get_direction_to(a: Hex, b: Hex) -> int:
	for i in range(6):
		if equals(neighbor(a, i), b):
			return i
	return -1


static func diagonal_neighbor(hex: Hex, direction_index: int) -> Hex:
	return add(hex, hex_diagonals[direction_index])


static func length(hex: Hex) -> int:
	return (abs(hex.q) + abs(hex.r) + abs(hex.s)) / 2


static func distance(a: Hex, b: Hex) -> int:
	return length(subtract(a, b))


static func round(hex: Hex) -> Hex:
	var rq = roundi(hex.q)
	var rr = roundi(hex.r)
	var rs = roundi(hex.s)
	var q_diff = abs(rq - hex.q)
	var r_diff = abs(rr - hex.r)
	var s_diff = abs(rs - hex.s)
	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	else:
		rs = -rq - rr
	return Hex.new(rq, rr, rs)


static func lerp(a: Hex, b: Hex, t: float) -> Hex:
	return Hex.new(a.q * (1.0 - t) + b.q * t, a.r * (1.0 - t) + b.r * t, a.s * (1.0 - t) + b.s * t)


static func linedraw(a: Hex, b: Hex) -> Array[Hex]:
	var dist = distance(a, b)
	var a_nudge = Hex.new(a.q + 1e-06, a.r + 1e-06, a.s - 2e-06)
	var b_nudge = Hex.new(b.q + 1e-06, b.r + 1e-06, b.s - 2e-06)
	var results: Array[Hex] = []
	var step = 1.0 / max(dist, 1)
	for i in range(0, dist + 1):
		results.append(Hex.round(Hex.lerp(a_nudge, b_nudge, step * i)))
	return results
