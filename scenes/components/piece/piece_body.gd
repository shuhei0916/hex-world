@tool
class_name PieceBody
extends Node2D
## 設置物の本体（shapez の建物のような見た目）。占めるマスを合わせた1つの形を、
## マスの縁より INSET だけ内側に縮めて角を丸め、種類ごとの色で塗って濃い線で縁取る。
## 中央には、機械なら作っている品物のアイコンを出す。
## 地面（床や鉱床）はマス全体を塗るので、縁のすき間から地面がのぞく。

## マスの縁から本体の縁までの距離（ピクセル）
const INSET := 3.0
## 角の丸みの半径
const CORNER_RADIUS := 9.0
## 縁取りの色と太さ。品目のアイコンの線と同じ色
const OUTLINE_COLOR := Color("#3c4652")
const OUTLINE_WIDTH := 3.5
## 中央のアイコンの大きさ（ピクセル）と濃さ
const ICON_SIZE := 40.0
const ICON_ALPHA := 0.9

var _outline := PackedVector2Array()
var _fill_color := Color.WHITE
var _icon: Texture2D = null
var _icon_center := Vector2.ZERO


## hexes（ピースの中の座標）を合わせた形の本体にし、color（種類ごとの色）で塗る。
func setup(hexes: Array, color: Color) -> void:
	_fill_color = color
	var layout := Layout.make_default()
	_outline = _rounded_inset(HexShape.union_outline(layout, hexes))
	_icon_center = _center_hex_position(layout, hexes)
	queue_redraw()


func get_fill_color() -> Color:
	return _fill_color


## 描いている本体の輪郭（最初の頂点には戻らない）
func get_outline() -> PackedVector2Array:
	return _outline


## 中央に描くアイコン。null なら描かない
func set_icon(icon: Texture2D) -> void:
	_icon = icon
	queue_redraw()


func get_icon() -> Texture2D:
	return _icon


func get_icon_center() -> Vector2:
	return _icon_center


# 形の重心に最も近いマスの中央。L字などでも、アイコンが形からはみ出さないようにマスの上に置く
static func _center_hex_position(layout: Layout, hexes: Array) -> Vector2:
	if hexes.is_empty():
		return Vector2.ZERO
	var centroid := Vector2.ZERO
	for hex in hexes:
		centroid += Layout.hex_to_pixel(layout, hex)
	centroid /= hexes.size()
	var best := Layout.hex_to_pixel(layout, hexes[0])
	for hex in hexes:
		var pos := Layout.hex_to_pixel(layout, hex)
		if pos.distance_to(centroid) < best.distance_to(centroid) - 0.001:
			best = pos
	return best


# 縁から INSET だけ縮め、出っ張った角を CORNER_RADIUS で丸める
# （いったん INSET + 半径まで縮めてから、丸い継ぎ目で半径ぶん広げ直す）
static func _rounded_inset(outline: PackedVector2Array) -> PackedVector2Array:
	if outline.is_empty():
		return outline
	var shrunk := Geometry2D.offset_polygon(
		outline, -(INSET + CORNER_RADIUS), Geometry2D.JOIN_MITER
	)
	if shrunk.is_empty():
		return PackedVector2Array()
	var grown := Geometry2D.offset_polygon(shrunk[0], CORNER_RADIUS, Geometry2D.JOIN_ROUND)
	return grown[0] if not grown.is_empty() else PackedVector2Array()


func _draw() -> void:
	if _outline.size() < 3:
		return
	draw_colored_polygon(_outline, _fill_color)
	var closed := _outline.duplicate()
	closed.append(_outline[0])
	draw_polyline(closed, OUTLINE_COLOR, OUTLINE_WIDTH, true)
	if _icon:
		var size := Vector2(ICON_SIZE, ICON_SIZE)
		draw_texture_rect(
			_icon, Rect2(_icon_center - size * 0.5, size), false, Color(1, 1, 1, ICON_ALPHA)
		)
