@tool
class_name Hex
extends RefCounted

var q
var r  
var s

func _init(q_val, r_val, s_val = null):
	q = q_val
	r = r_val
	if s_val == null:
		# 2引数コンストラクタ: s = -q - r で自動計算
		s = -q_val - r_val
	else:
		# 3引数コンストラクタ: s値を直接設定
		s = s_val

func is_valid() -> bool:
	return (q + r + s) == 0

func _to_string() -> String:
	return "(%s, %s, %s)" % [q, r, s]

# 六角形算術演算（本家 redblob_hex.py に準拠）
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

# 六角形方向システム（本家 redblob_hex.py に準拠）
static var HEX_DIRECTIONS = [
	Hex.new(1, 0, -1),   # 方向0
	Hex.new(1, -1, 0),   # 方向1
	Hex.new(0, -1, 1),   # 方向2
	Hex.new(-1, 0, 1),   # 方向3
	Hex.new(-1, 1, 0),   # 方向4
	Hex.new(0, 1, -1)    # 方向5
]

static func direction(direction: int) -> Hex:
	return HEX_DIRECTIONS[direction]

static func neighbor(hex: Hex, direction: int) -> Hex:
	return add(hex, direction(direction))

# 六角形対角線方向システム（本家 redblob_hex.py に準拠）
static var HEX_DIAGONALS = [
	Hex.new(2, -1, -1),   # 対角線方向0
	Hex.new(1, -2, 1),    # 対角線方向1
	Hex.new(-1, -1, 2),   # 対角線方向2
	Hex.new(-2, 1, 1),    # 対角線方向3
	Hex.new(-1, 2, -1),   # 対角線方向4
	Hex.new(1, 1, -2)     # 対角線方向5
]

static func diagonal_neighbor(hex: Hex, direction: int) -> Hex:
	return add(hex, HEX_DIAGONALS[direction])

# 六角形距離と補間（本家 redblob_hex.py に準拠）
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
	return Hex.new(
		a.q * (1.0 - t) + b.q * t,
		a.r * (1.0 - t) + b.r * t,
		a.s * (1.0 - t) + b.s * t
	)

static func linedraw(a: Hex, b: Hex) -> Array[Hex]:
	var N = distance(a, b)
	var a_nudge = Hex.new(a.q + 1e-06, a.r + 1e-06, a.s - 2e-06)
	var b_nudge = Hex.new(b.q + 1e-06, b.r + 1e-06, b.s - 2e-06)
	var results: Array[Hex] = []
	var step = 1.0 / max(N, 1)
	for i in range(0, N + 1):
		results.append(Hex.round(Hex.lerp(a_nudge, b_nudge, step * i)))
	return results
