@tool
class_name Layout
extends RefCounted

# Layout - 「論理上のHex座標 (q, r)」と「画面上のピクセル座標 (x, y)」を相互変換するための計算式と設定をまとめたクラス
# 式は Red Blob Games の "Hexagonal Grids" による（f0〜f3: マス→画面、b0〜b3: 画面→マス）

# 頂点が上の向き（chunk の盤面）
static var layout_pointy = Orientation.new(
	sqrt(3.0), sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0
)

# 辺が上の向き（ワールドマップ）
static var layout_flat = Orientation.new(
	3.0 / 2.0, 0.0, sqrt(3.0) / 2.0, sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, sqrt(3.0) / 3.0
)

var orientation: Orientation
var size: Vector2
var origin: Vector2


func _init(orientation_val: Orientation, size_val: Vector2, origin_val: Vector2):
	orientation = orientation_val
	size = size_val
	origin = origin_val


static func make_default() -> Layout:
	return Layout.new(layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)


static func hex_to_pixel(layout: Layout, h: Vector2i) -> Vector2:
	var matrix = layout.orientation
	var size = layout.size
	var origin = layout.origin
	var x = (matrix.f0 * h.x + matrix.f1 * h.y) * size.x
	var y = (matrix.f2 * h.x + matrix.f3 * h.y) * size.y
	return Vector2(x + origin.x, y + origin.y)


# 小数の軸座標を Vector2(q, r) で返す
static func pixel_to_hex_fractional(layout: Layout, p: Vector2) -> Vector2:
	var matrix = layout.orientation
	var size = layout.size
	var origin = layout.origin
	var pt = Vector2((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
	var q = matrix.b0 * pt.x + matrix.b1 * pt.y
	var r = matrix.b2 * pt.x + matrix.b3 * pt.y
	return Vector2(q, r)


static func pixel_to_hex_rounded(layout: Layout, p: Vector2) -> Vector2i:
	return Hex.round(pixel_to_hex_fractional(layout, p))
