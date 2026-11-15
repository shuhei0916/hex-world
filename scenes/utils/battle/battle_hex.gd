class_name BattleHex
## 軸座標（q, r）で表したヘックスの計算をまとめたもの。座標は Vector2i(q, r) で持つ。

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in DIRECTIONS:
		result.append(hex + direction)
	return result


static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := b - a
	return maxi(maxi(absi(d.x), absi(d.y)), absi(d.x + d.y))


static func within(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			result.append(center + Vector2i(q, r))
	return result


static func line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var steps := distance(from, to)
	var result: Array[Vector2i] = []
	for i in range(steps + 1):
		var t := float(i) / steps if steps > 0 else 0.0
		result.append(round_fractional(Vector2(from).lerp(Vector2(to), t)))
	return result


## 小数の軸座標を最も近いヘックスに丸める。
static func round_fractional(fractional: Vector2) -> Vector2i:
	var q := roundf(fractional.x)
	var r := roundf(fractional.y)
	var s := roundf(-fractional.x - fractional.y)
	var dq := absf(q - fractional.x)
	var dr := absf(r - fractional.y)
	var ds := absf(s + fractional.x + fractional.y)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(int(q), int(r))


## ヘックスの中心の画面座標を返す。頂点が上の向きで、size は中心から頂点までの長さ。
static func to_pixel(hex: Vector2i, size: float) -> Vector2:
	return Vector2(size * sqrt(3.0) * (hex.x + hex.y / 2.0), size * 1.5 * hex.y)


static func from_pixel(pixel: Vector2, size: float) -> Vector2i:
	var r := pixel.y / (size * 1.5)
	var q := pixel.x / (size * sqrt(3.0)) - r / 2.0
	return round_fractional(Vector2(q, r))
