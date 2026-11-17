@tool
class_name Hex
## ヘックスの座標の計算をまとめたもの。座標は軸座標（q, r）を Vector2i(q, r) で持つ。
## 足し算・引き算・比較・辞書のキーには Vector2i をそのまま使う。
## 3つ目の座標 s は -q - r で決まるので持たず、必要なときに s() で求める。

const DIR_NAME_TO_INDEX = {"E": 0, "NE": 1, "NW": 2, "W": 3, "SW": 4, "SE": 5}

## 隣のマスへの6方向。東から反時計回り。
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),  # 東 (E)
	Vector2i(1, -1),  # 北東 (NE)
	Vector2i(0, -1),  # 北西 (NW)
	Vector2i(-1, 0),  # 西 (W)
	Vector2i(-1, 1),  # 南西 (SW)
	Vector2i(0, 1),  # 南東 (SE)
]

## 頂点の先にあるマスへの6方向。
const DIAGONALS: Array[Vector2i] = [
	Vector2i(2, -1),
	Vector2i(1, -2),
	Vector2i(-1, -1),
	Vector2i(-2, 1),
	Vector2i(-1, 2),
	Vector2i(1, 1),
]


## 3つ目の座標。
static func s(hex: Vector2i) -> int:
	return -hex.x - hex.y


static func rotate_left(hex: Vector2i) -> Vector2i:
	return Vector2i(-s(hex), -hex.x)


static func rotate_right(hex: Vector2i) -> Vector2i:
	return Vector2i(-hex.y, -s(hex))


## offset を右回りに rotation 回だけ回転させて返す。
## ピースの形の定義を rotation_state に追従させるときに使う。
static func from_offset_rotated(offset: Vector2i, rotation: int) -> Vector2i:
	var hex := offset
	for _i in range(rotation):
		hex = rotate_right(hex)
	return hex


static func direction(direction_index: int) -> Vector2i:
	return DIRECTIONS[direction_index]


static func neighbor(hex: Vector2i, direction_index: int) -> Vector2i:
	return hex + DIRECTIONS[direction_index]


static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in DIRECTIONS:
		result.append(hex + offset)
	return result


## a から見て b がどの方向の隣か。隣でなければ -1。
static func get_direction_to(a: Vector2i, b: Vector2i) -> int:
	return DIRECTIONS.find(b - a)


static func diagonal_neighbor(hex: Vector2i, direction_index: int) -> Vector2i:
	return hex + DIAGONALS[direction_index]


## 原点からの距離。
static func length(hex: Vector2i) -> int:
	return maxi(maxi(absi(hex.x), absi(hex.y)), absi(s(hex)))


static func distance(a: Vector2i, b: Vector2i) -> int:
	return length(b - a)


## center から radius マス以内のマスをすべて返す。
static func within(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			result.append(center + Vector2i(q, r))
	return result


## 小数の軸座標を最も近いマスに丸める。
static func round(fractional: Vector2) -> Vector2i:
	var q := roundf(fractional.x)
	var r := roundf(fractional.y)
	var rounded_s := roundf(-fractional.x - fractional.y)
	var dq := absf(q - fractional.x)
	var dr := absf(r - fractional.y)
	var ds := absf(rounded_s + fractional.x + fractional.y)
	if dq > dr and dq > ds:
		q = -r - rounded_s
	elif dr > ds:
		r = -q - rounded_s
	return Vector2i(int(q), int(r))


## from から to までの直線上のマス。両端を含む。
static func line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var steps := distance(from, to)
	# マスの境界ちょうどを通るときに丸めがぶれないよう、わずかにずらす
	var nudge := Vector2(1e-06, 1e-06)
	var result: Array[Vector2i] = []
	for i in range(steps + 1):
		var t := float(i) / steps if steps > 0 else 0.0
		result.append(Hex.round((Vector2(from) + nudge).lerp(Vector2(to) + nudge, t)))
	return result


## マスの中心の画面座標を返す。頂点が上の向きで、size は中心から頂点までの長さ。
static func to_pixel(hex: Vector2i, size: float) -> Vector2:
	return Vector2(size * sqrt(3.0) * (hex.x + hex.y / 2.0), size * 1.5 * hex.y)


## 画面座標にあるマスを返す。to_pixel の逆。
static func from_pixel(pixel: Vector2, size: float) -> Vector2i:
	var r := pixel.y / (size * 1.5)
	var q := pixel.x / (size * sqrt(3.0)) - r / 2.0
	return Hex.round(Vector2(q, r))
