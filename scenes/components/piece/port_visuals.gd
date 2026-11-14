class_name PortVisuals
extends Node2D

## 施設の出入口の描画。コンベアと同じ幅・色の短いベルト（口）を施設のタイルの下に描き、
## タイルと辺のすき間だけが見えるようにする。隣のコンベアが施設に差し込まれているように見え、
## 施設そのものは覆わない。向きは施設のタイルの上に小さな印（PortMarkers）で示す
## （shapez の建物の出入口に相当）。
##
## 出口は施設の出力ポートから決まる。入口は、実際に流し込んでくる隣のピースがある位置にだけ描く
## （Chunk の NeighborManager が set_input_ports で知らせる）。

const STUB_WIDTH := ConveyorVisuals.BELT_WIDTH
# 施設のタイルの z（Piece の基礎タイル）
const PIECE_TILE_Z := 10
# 口のベルトの z。コンベア(6)より手前、施設のタイルより奥
const Z_INDEX := 9
# 向きの印の z。施設のタイルより手前
const MARKER_Z_INDEX := 11
# 施設のタイル画像の内接円の半径。画像(256px×0.3)は辺のすき間ぶんマスより小さい
const TILE_INRADIUS := 33.0
# 口の内側の端の位置。マスの中心(0)から辺の中点(1)までの割合。タイルの下に隠れる位置にする
const INNER_RATIO := 0.75
# 隣のマスへはみ出させる長さ。辺でぴったり止めると、隣のベルトとの間にすき間が見える
const OVERLAP := 1.5
const FILL_COLOR := Color(0.77, 0.77, 0.77, 1.0)
const EDGE_COLOR := Color(0.54, 0.54, 0.57, 1.0)
const MARKER_COLOR := Color(0.12, 0.12, 0.14, 0.85)
const MARKER_SIZE := 6.0
# 印を置く位置。マスの中心から辺の中点までの割合（タイルの縁の少し内側）
const MARKER_RATIO := 0.7

var _input_ports: Array = []  # [{hex: 施設内の位置, direction: 流し込んでくる側の辺}]
var _markers := Node2D.new()

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
	_markers.name = "PortMarkers"
	_markers.z_index = MARKER_Z_INDEX
	_markers.z_as_relative = false
	_markers.draw.connect(_draw_markers)
	add_child(_markers)
	_piece.shape_changed.connect(_redraw)


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
	_redraw()


func _redraw() -> void:
	queue_redraw()
	_markers.queue_redraw()


func _draw() -> void:
	for stub in get_input_stubs() + get_output_stubs():
		var segment = stub_segment(stub["hex"], stub["direction"])
		draw_line(segment[0], segment[1], EDGE_COLOR, STUB_WIDTH)
		draw_line(segment[0], segment[1], FILL_COLOR, STUB_WIDTH - 6.0)


func _draw_markers() -> void:
	for stub in get_input_stubs():
		_draw_marker(stub["hex"], stub["direction"], false)
	for stub in get_output_stubs():
		_draw_marker(stub["hex"], stub["direction"], true)


func _draw_marker(hex: Hex, direction: int, is_output: bool) -> void:
	var layout = Layout.make_default()
	var center = Layout.hex_to_pixel(layout, hex)
	var to_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[direction]) * 0.5
	var pos = center + to_edge * MARKER_RATIO
	var tangent = to_edge.normalized() if is_output else -to_edge.normalized()
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * MARKER_SIZE
	var left = pos - tangent * (MARKER_SIZE * 0.5) + perp * MARKER_SIZE
	var right = pos - tangent * (MARKER_SIZE * 0.5) - perp * MARKER_SIZE
	_markers.draw_colored_polygon(PackedVector2Array([tip, left, right]), MARKER_COLOR)
