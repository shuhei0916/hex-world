class_name Hex
extends RefCounted

var q: int
var r: int  
var s: int

func _init(q_val: int, r_val: int, s_val: int):
	q = q_val
	r = r_val
	s = s_val

func is_valid() -> bool:
	return (q + r + s) == 0

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