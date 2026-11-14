class_name PortVisuals
extends Node2D

## 施設の出入口の描画。施設のマスの中からマスの辺まで、コンベアと同じ幅・色の短いベルト
## （口）を描き、矢印で向きを示す。隣のコンベアと途切れずつながって見え、
## どこから出てどこへ入るかが分かるようにする（shapez の建物の出入口に相当）。
##
## 出口は施設の出力ポートから決まる。入口は、実際に流し込んでくる隣のピースがある位置にだけ描く
## （Chunk の NeighborManager が set_input_ports で知らせる）。

const STUB_WIDTH := ConveyorVisuals.BELT_WIDTH
# 口の内側の端の位置。マスの中心(0)から辺の中点(1)までの割合
const INNER_RATIO := 0.3
# 隣のマスへはみ出させる長さ。辺でぴったり止めると、隣のベルトとの間にすき間が見える
const OVERLAP := 1.5
const FILL_COLOR := Color(0.77, 0.77, 0.77, 1.0)
const EDGE_COLOR := Color(0.54, 0.54, 0.57, 1.0)
const ARROW_COLOR := Color(0.3, 0.3, 0.34, 1.0)
const ARROW_SIZE := 9.0
# 施設のタイル(10)より手前
const Z_INDEX := 11

var _input_ports: Array = []  # [{hex: 施設内の位置, direction: 流し込んでくる側の辺}]

@onready var _piece: Piece = get_parent()


# 口の線分 [内側の端, 外側の端]。hex は施設内の位置、direction は口のある辺(0-5)。
static func stub_segment(hex: Hex, direction: int) -> Array:
	var layout = Layout.make_default()
	var center = Layout.hex_to_pixel(layout, hex)
	var to_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[direction]) * 0.5
	var outward = to_edge.normalized()
	return [center + to_edge * INNER_RATIO, center + to_edge + outward * OVERLAP]


func _ready() -> void:
	z_index = Z_INDEX
	z_as_relative = false
	_piece.shape_changed.connect(queue_redraw)


# 出口 [{hex, direction}]。Sender の出力は chunk の外へ向かう配線なので描かない。
func get_output_stubs() -> Array:
	if _piece.piece_type == PieceData.Type.SENDER:
		return []
	return _piece.get_output_ports()


# 入口 [{hex, direction}]
func get_input_stubs() -> Array:
	return _input_ports


func set_input_ports(ports: Array) -> void:
	_input_ports = ports
	queue_redraw()


func _draw() -> void:
	for stub in get_input_stubs():
		_draw_stub(stub["hex"], stub["direction"], false)
	for stub in get_output_stubs():
		_draw_stub(stub["hex"], stub["direction"], true)


func _draw_stub(hex: Hex, direction: int, is_output: bool) -> void:
	var segment = stub_segment(hex, direction)
	var inner: Vector2 = segment[0]
	var outer: Vector2 = segment[1]
	# 内側の端は丸めて、施設の中から生えているように見せる
	draw_circle(inner, STUB_WIDTH * 0.5, EDGE_COLOR)
	draw_line(inner, outer, EDGE_COLOR, STUB_WIDTH)
	draw_circle(inner, STUB_WIDTH * 0.5 - 3.0, FILL_COLOR)
	draw_line(inner, outer, FILL_COLOR, STUB_WIDTH - 6.0)
	var outward = (outer - inner).normalized()
	var tangent = outward if is_output else -outward
	_draw_arrow(inner.lerp(outer, 0.5), tangent)


func _draw_arrow(pos: Vector2, tangent: Vector2) -> void:
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * ARROW_SIZE
	var left = pos - tangent * (ARROW_SIZE * 0.5) + perp * (ARROW_SIZE * 0.85)
	var right = pos - tangent * (ARROW_SIZE * 0.5) - perp * (ARROW_SIZE * 0.85)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), ARROW_COLOR)
