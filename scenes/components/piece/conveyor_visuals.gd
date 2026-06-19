class_name ConveyorVisuals
extends Node2D

const BELT_WIDTH = 40.0
const CURVE_SEGMENTS = 12

const _BELT_FILL := Color(0.77, 0.77, 0.77, 1.0)
const _BELT_EDGE := Color(0.54, 0.54, 0.57, 1.0)
const _BELT_ARROW := Color(0.62, 0.62, 0.62, 1.0)
const _ARROW_SPACING := 30.0
const _ARROW_SIZE := 8.0

var _path: PackedVector2Array = PackedVector2Array()
var _input_direction: int = -1
var _elapsed: float = 0.0

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


static func sample_bezier(
	p0: Vector2, ctrl: Vector2, p2: Vector2, segments: int
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / segments
		var mt = 1.0 - t
		pts.append(mt * mt * p0 + 2.0 * mt * t * ctrl + t * t * p2)
	return pts


func _ready():
	z_index = 6
	z_as_relative = false
	_item_icon.z_index = 7
	_item_icon.z_as_relative = false
	_piece.shape_changed.connect(refresh_belt)
	refresh_belt()


func _find_mover() -> Node:
	for sibling in get_parent().get_children():
		if sibling.has_method("get_held_item"):
			return sibling
	return null


func _process(delta: float):
	_elapsed += delta
	queue_redraw()
	update_item_icon()


func set_input_direction(direction: int):
	_input_direction = direction
	refresh_belt()


func refresh_belt():
	_path = PackedVector2Array()
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	var is_straight = (input_dir + 3) % 6 == output_dir
	var segs = 2 if is_straight else CURVE_SEGMENTS
	_path = sample_bezier(in_edge, Vector2.ZERO, out_edge, segs)
	queue_redraw()


func _draw():
	if _path.size() < 2:
		return
	draw_polyline(_path, _BELT_EDGE, BELT_WIDTH, true)
	draw_polyline(_path, _BELT_FILL, BELT_WIDTH - 6.0, true)
	_draw_belt_arrows()


func _draw_belt_arrows():
	var total_len := _path_arc_length()
	if total_len < 1.0:
		return
	var anim_offset: float = fmod(
		_elapsed * total_len / TransferBuffer.TRANSFER_TIME, _ARROW_SPACING
	)
	var dist: float = 0.0
	var next_arrow: float = anim_offset
	for i in range(_path.size() - 1):
		var seg_len = (_path[i + 1] - _path[i]).length()
		while next_arrow <= dist + seg_len:
			var local_t = (next_arrow - dist) / seg_len
			var pos = _path[i].lerp(_path[i + 1], local_t)
			var tangent = (_path[i + 1] - _path[i]).normalized()
			_draw_chevron(pos, tangent)
			next_arrow += _ARROW_SPACING
		dist += seg_len


func _draw_chevron(pos: Vector2, tangent: Vector2):
	var perp = tangent.rotated(PI * 0.5)
	var tip = pos + tangent * _ARROW_SIZE
	var left = pos - tangent * (_ARROW_SIZE * 0.4) + perp * (_ARROW_SIZE * 0.7)
	var right = pos - tangent * (_ARROW_SIZE * 0.4) - perp * (_ARROW_SIZE * 0.7)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), _BELT_ARROW)


func _path_arc_length() -> float:
	var total := 0.0
	for i in range(_path.size() - 1):
		total += (_path[i + 1] - _path[i]).length()
	return total


# ---- アイテムアイコン --------------------------------------------------------


func update_item_icon():
	if not _mover or not _item_icon:
		return
	var held_item = _mover.get_held_item()
	if held_item == "":
		_item_icon.visible = false
		return
	var item_def = ItemDB.get_item(held_item)
	if not item_def:
		_item_icon.visible = false
		return
	_item_icon.texture = item_def.icon
	_item_icon.visible = true
	_item_icon.position = _item_position_on_path()


func _item_position_on_path() -> Vector2:
	if _path.size() < 2:
		return Vector2.ZERO
	var t = _mover.get_progress_ratio()
	var n = _path.size() - 1
	var fi = t * n
	var i = clampi(int(fi), 0, n - 1)
	return _path[i].lerp(_path[i + 1], fi - i)
