@tool
class_name Layout
extends RefCounted

# Layout - 「論理上のHex座標 (q, r)」と「画面上のピクセル座標 (x,　y)」を相互変換するための計算式と設定をまとめたクラス

var orientation: Orientation
var size: Vector2
var origin: Vector2

func _init(orientation_val: Orientation, size_val: Vector2, origin_val: Vector2):
	orientation = orientation_val
	size = size_val
	origin = origin_val


# layout_pointy = Orientation(math.sqrt(3.0), math.sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, math.sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5)
static var layout_pointy = Orientation.new(
	sqrt(3.0), sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0,
	sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5
)

# layout_flat = Orientation(3.0 / 2.0, 0.0, math.sqrt(3.0) / 2.0, math.sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, math.sqrt(3.0) / 3.0, 0.0)
static var layout_flat = Orientation.new(
	3.0 / 2.0, 0.0, sqrt(3.0) / 2.0, sqrt(3.0),
	2.0 / 3.0, 0.0, -1.0 / 3.0, sqrt(3.0) / 3.0, 0.0
)

# def hex_to_pixel(layout, h):
#     M = layout.orientation
#     size = layout.size
#     origin = layout.origin
#     x = (M.f0 * h.q + M.f1 * h.r) * size.x
#     y = (M.f2 * h.q + M.f3 * h.r) * size.y
#     return Point(x + origin.x, y + origin.y)

static func hex_to_pixel(layout: Layout, h: Hex) -> Vector2:
	var M = layout.orientation
	var size = layout.size
	var origin = layout.origin
	var x = (M.f0 * h.q + M.f1 * h.r) * size.x
	var y = (M.f2 * h.q + M.f3 * h.r) * size.y
	return Vector2(x + origin.x, y + origin.y)

# def pixel_to_hex_fractional(layout, p):
#     M = layout.orientation
#     size = layout.size
#     origin = layout.origin
#     pt = Point((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
#     q = M.b0 * pt.x + M.b1 * pt.y
#     r = M.b2 * pt.x + M.b3 * pt.y
#     return Hex(q, r, -q - r)

static func pixel_to_hex_fractional(layout: Layout, p: Vector2) -> Hex:
	var M = layout.orientation
	var size = layout.size
	var origin = layout.origin
	var pt = Vector2((p.x - origin.x) / size.x, (p.y - origin.y) / size.y)
	var q = M.b0 * pt.x + M.b1 * pt.y
	var r = M.b2 * pt.x + M.b3 * pt.y
	return Hex.new(q, r, -q - r)

# def pixel_to_hex_rounded(layout, p):
#     return hex_round(pixel_to_hex_fractional(layout, p))

static func pixel_to_hex_rounded(layout: Layout, p: Vector2) -> Hex:
	return Hex.round(pixel_to_hex_fractional(layout, p))
