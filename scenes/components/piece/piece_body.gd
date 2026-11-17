@tool
class_name PieceBody
extends Node2D
## 設置物の本体。占めるマスを合わせた1つの形を、マスの縁より INSET だけ内側に縮めて描く。
## 地面（床や鉱床）はマス全体を塗るので、縮めたすき間から地面がのぞき、
## 「マスの上に置かれた物」として地面の種類と見分けられる。

## マスの縁から本体の縁までの距離（ピクセル）
const INSET := 6.0

var _outline := PackedVector2Array()
var _fill_color := Color.WHITE


## hexes（ピースの中の座標）を合わせた形を、color で塗って描く。
func setup(hexes: Array, color: Color) -> void:
	_fill_color = color
	_outline = _inset(HexShape.union_outline(Layout.make_default(), hexes))
	queue_redraw()


func get_fill_color() -> Color:
	return _fill_color


## 描いている本体の輪郭（最初の頂点には戻らない）
func get_outline() -> PackedVector2Array:
	return _outline


static func _inset(outline: PackedVector2Array) -> PackedVector2Array:
	if outline.is_empty():
		return outline
	var shrunk := Geometry2D.offset_polygon(outline, -INSET, Geometry2D.JOIN_MITER)
	return shrunk[0] if not shrunk.is_empty() else PackedVector2Array()


func _draw() -> void:
	if _outline.size() < 3:
		return
	draw_colored_polygon(_outline, _fill_color)
	var closed := _outline.duplicate()
	closed.append(_outline[0])
	var border := Color(HexStyle.BORDER_COLOR, HexStyle.BORDER_COLOR.a * _fill_color.a)
	draw_polyline(closed, border, HexStyle.BORDER_WIDTH)
