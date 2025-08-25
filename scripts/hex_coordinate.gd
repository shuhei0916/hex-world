class_name HexCoordinate
extends RefCounted

var q: int
var r: int
var s: int

# 六角形の6方向の隣接セルのオフセット (point top hexagons)
const HEX_DIRECTIONS = [
	[1, 0, -1],   # 方向0: 右
	[1, -1, 0],   # 方向1: 右上
	[0, -1, 1],   # 方向2: 左上  
	[-1, 0, 1],   # 方向3: 左
	[-1, 1, 0],   # 方向4: 左下
	[0, 1, -1]    # 方向5: 右下
]

# 六角形の6方向の対角隣接セルのオフセット (point top hexagons)
const HEX_DIAGONALS = [
	[2, -1, -1],  # 対角方向0
	[1, -2, 1],   # 対角方向1
	[-1, -1, 2],  # 対角方向2
	[-2, 1, 1],   # 対角方向3
	[-1, 2, -1],  # 対角方向4
	[1, 1, -2]    # 対角方向5
]

func _init(q_val: int, r_val: int, s_val: int):
	q = q_val
	r = r_val
	s = s_val

func is_valid() -> bool:
	return q + r + s == 0

func add(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q + other.q, r + other.r, s + other.s)

func subtract(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q - other.q, r - other.r, s - other.s)

func scale(factor: int) -> HexCoordinate:
	return HexCoordinate.new(q * factor, r * factor, s * factor)

func neighbor(direction: int) -> HexCoordinate:
	var dir = HEX_DIRECTIONS[direction]
	return HexCoordinate.new(q + dir[0], r + dir[1], s + dir[2])

func diagonal_neighbor(direction: int) -> HexCoordinate:
	var diag = HEX_DIAGONALS[direction]
	return HexCoordinate.new(q + diag[0], r + diag[1], s + diag[2])

func distance(other: HexCoordinate) -> int:
	return (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2