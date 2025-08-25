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
	# Red Blob Games準拠: 作成後すぐに制約を警告（ログ出力）
	if not is_valid():
		push_warning("HexCoordinate created with invalid constraint: q=%d, r=%d, s=%d (q+r+s=%d, should be 0)" % [q, r, s, q+r+s])

# Red Blob Games準拠: 検証済み作成関数
static func create_validated(q_val: int, r_val: int, s_val: int) -> HexCoordinate:
	if q_val + r_val + s_val != 0:
		push_error("Invalid hex coordinate: q + r + s must be 0, got q=%d, r=%d, s=%d (sum=%d)" % [q_val, r_val, s_val, q_val + r_val + s_val])
		return null
	return HexCoordinate.new(q_val, r_val, s_val)

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

# Red Blob Games準拠: 方向ベクトル取得
static func direction(direction_index: int) -> HexCoordinate:
	var dir = HEX_DIRECTIONS[direction_index]
	return HexCoordinate.new(dir[0], dir[1], dir[2])

func diagonal_neighbor(direction: int) -> HexCoordinate:
	var diag = HEX_DIAGONALS[direction]
	return HexCoordinate.new(q + diag[0], r + diag[1], s + diag[2])

func distance(other: HexCoordinate) -> int:
	return (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2

# Red Blob Games準拠: 六角形座標回転
func rotate_left() -> HexCoordinate:
	return HexCoordinate.new(-s, -q, -r)

func rotate_right() -> HexCoordinate:
	return HexCoordinate.new(-r, -s, -q)

# Point-top hexagon pixel conversion (Red Blob Games implementation)
func to_pixel(size: float, origin: Vector2) -> Vector2:
	var sqrt3 = sqrt(3.0)
	var x = size * (sqrt3 * q + sqrt3/2.0 * r)
	var y = size * (3.0/2.0 * r)
	return Vector2(x + origin.x, y + origin.y)

static func from_pixel(pixel: Vector2, size: float, origin: Vector2) -> HexCoordinate:
	var sqrt3 = sqrt(3.0)
	var pt = Vector2(pixel.x - origin.x, pixel.y - origin.y)
	var q_frac = (sqrt3/3.0 * pt.x - 1.0/3.0 * pt.y) / size
	var r_frac = (2.0/3.0 * pt.y) / size
	var s_frac = -q_frac - r_frac
	return hex_round(q_frac, r_frac, s_frac)

static func hex_round(q_frac: float, r_frac: float, s_frac: float) -> HexCoordinate:
	var q_round = round(q_frac)
	var r_round = round(r_frac)
	var s_round = round(s_frac)
	
	var q_diff = abs(q_round - q_frac)
	var r_diff = abs(r_round - r_frac)
	var s_diff = abs(s_round - s_frac)
	
	if q_diff > r_diff and q_diff > s_diff:
		q_round = -r_round - s_round
	elif r_diff > s_diff:
		r_round = -q_round - s_round
	else:
		s_round = -q_round - r_round
	
	return HexCoordinate.new(int(q_round), int(r_round), int(s_round))

# Red Blob Games準拠: 分数座標クラス
class HexFractional:
	var q: float
	var r: float
	var s: float
	
	func _init(q_val: float, r_val: float, s_val: float):
		q = q_val
		r = r_val
		s = s_val

# Red Blob Games準拠: 線形補間
static func lerp(hex_a: HexCoordinate, hex_b: HexCoordinate, t: float) -> HexFractional:
	var q_lerp = hex_a.q * (1.0 - t) + hex_b.q * t
	var r_lerp = hex_a.r * (1.0 - t) + hex_b.r * t
	var s_lerp = hex_a.s * (1.0 - t) + hex_b.s * t
	return HexFractional.new(q_lerp, r_lerp, s_lerp)

# Red Blob Games準拠: 線描画（2点間の六角形パス）
static func line_draw(hex_a: HexCoordinate, hex_b: HexCoordinate) -> Array[HexCoordinate]:
	var N = hex_a.distance(hex_b)
	var results: Array[HexCoordinate] = []
	
	# nudge: 丸め誤差を避けるための微小な値
	var a_nudge = HexFractional.new(hex_a.q + 1e-06, hex_a.r + 1e-06, hex_a.s - 2e-06)
	var b_nudge = HexFractional.new(hex_b.q + 1e-06, hex_b.r + 1e-06, hex_b.s - 2e-06)
	
	var step = 1.0 / max(N, 1)
	for i in range(N + 1):
		var t = step * i
		var q_lerp = a_nudge.q * (1.0 - t) + b_nudge.q * t
		var r_lerp = a_nudge.r * (1.0 - t) + b_nudge.r * t
		var s_lerp = a_nudge.s * (1.0 - t) + b_nudge.s * t
		results.append(hex_round(q_lerp, r_lerp, s_lerp))
	
	return results