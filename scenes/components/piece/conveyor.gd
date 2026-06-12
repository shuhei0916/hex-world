@tool
class_name Conveyor
extends Piece

## コンベア専用ピース。容量1・位置ベースでアイテムを搬送する。
## インベントリを持たず、保持アイテムの管理は $ConveyorLogic に委譲する。

var _conveyor_line: Line2D = null
var _input_direction: int = -1

@onready var _logic: ConveyorLogic = get_node_or_null("ConveyorLogic")
@onready var _item_icon: Sprite2D = get_node_or_null("ItemIcon")


func setup(rotation: int = 0):
	super.setup(rotation)
	_refresh_conveyor_line()


func rotate_cw():
	super.rotate_cw()
	_refresh_conveyor_line()


func set_input_direction(direction: int):
	_input_direction = direction
	_refresh_conveyor_line()


func _refresh_conveyor_line():
	if _conveyor_line:
		_conveyor_line.queue_free()
		_conveyor_line = null
	if piece_type != PieceData.Type.CONVEYOR:
		return
	var ports = get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	_conveyor_line = Line2D.new()
	_conveyor_line.add_point(in_edge)
	_conveyor_line.add_point(Vector2.ZERO)
	_conveyor_line.add_point(out_edge)
	_conveyor_line.width = 10.0
	_conveyor_line.default_color = Color(0.9, 0.85, 0.6, 0.9)
	add_child(_conveyor_line)


func tick(delta: float):
	super.tick(delta)
	_update_item_icon()


func _update_item_icon():
	if not _item_icon:
		return
	if _logic.held_item == "":
		_item_icon.visible = false
		return
	var item_def = ItemDB.get_item(_logic.held_item)
	if not item_def:
		_item_icon.visible = false
		return
	_item_icon.texture = item_def.icon
	_item_icon.visible = true
	_item_icon.position = _item_position_on_line()


func _item_position_on_line() -> Vector2:
	if not _conveyor_line or _conveyor_line.get_point_count() < 3:
		return Vector2.ZERO
	var t = _logic.progress / ConveyorLogic.TRANSFER_TIME
	var in_edge = _conveyor_line.get_point_position(0)
	var center = _conveyor_line.get_point_position(1)
	var out_edge = _conveyor_line.get_point_position(2)
	if t < 0.5:
		return in_edge.lerp(center, t * 2.0)
	return center.lerp(out_edge, (t - 0.5) * 2.0)


func can_accept_item(item_name: String) -> bool:
	return _logic.can_accept_item(item_name)


func add_item(item_name: String, _amount: int):
	_logic.receive_item(item_name)


func get_item_count(item_name: String) -> int:
	return 1 if _logic.held_item == item_name else 0


func set_connected_pieces(pieces: Array) -> void:
	_logic.connected_pieces = pieces


func get_connected_pieces() -> Array:
	return _logic.connected_pieces
