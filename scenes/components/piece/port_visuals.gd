class_name PortVisuals
extends Node2D

## 施設の出口の向きの印。出力ポートのある辺の少し内側に小さな三角を描き、
## どの辺から排出するかを示す。入口には何も描かない（流し込むコンベアの向きで分かる）。

# 施設のタイルの z（Piece の基礎タイル）。印はこれより手前に描く
const PIECE_TILE_Z := 10
const Z_INDEX := 11
# 施設のタイル画像の内接円の半径。画像(256px×0.3)は辺のすき間ぶんマスより小さい
const TILE_INRADIUS := 33.0
const MARKER_COLOR := Color(0.12, 0.12, 0.14, 0.85)
const MARKER_SIZE := 6.0
# 印を置く位置。マスの中心(0)から辺の中点(1)までの割合（タイルの縁の少し内側）
const MARKER_RATIO := 0.7

@onready var _piece: Piece = get_parent()


# 出口の印の中心。hex は施設内の位置、direction は出口のある辺(0-5)
static func marker_position(hex: Hex, direction: int) -> Vector2:
	var layout = Layout.make_default()
	var center = Layout.hex_to_pixel(layout, hex)
	var to_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[direction]) * 0.5
	return center + to_edge * MARKER_RATIO


func _ready() -> void:
	z_index = Z_INDEX
	z_as_relative = false
	_piece.shape_changed.connect(queue_redraw)


# 出口 [{hex, direction}]。Sender の出力は chunk の外へ向かう配線なので描かない。
func get_output_stubs() -> Array:
	if _piece.piece_type == PieceData.Type.SENDER:
		return []
	return _piece.get_output_ports()


func _draw() -> void:
	for stub in get_output_stubs():
		_draw_marker(stub["hex"], stub["direction"])


func _draw_marker(hex: Hex, direction: int) -> void:
	var pos = marker_position(hex, direction)
	var tangent = Layout.hex_to_pixel(Layout.make_default(), Hex.hex_directions[direction])
	tangent = tangent.normalized()
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * MARKER_SIZE
	var left = pos - tangent * (MARKER_SIZE * 0.5) + perp * MARKER_SIZE
	var right = pos - tangent * (MARKER_SIZE * 0.5) - perp * MARKER_SIZE
	draw_colored_polygon(PackedVector2Array([tip, left, right]), MARKER_COLOR)
