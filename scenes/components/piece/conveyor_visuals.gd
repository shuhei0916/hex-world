class_name ConveyorVisuals
extends Node2D

## コンベア/スプリッターのライン描画と保持アイテムのアイコン表示を担当する。
## 搬送状態は兄弟の mover（get_held_item を持つ ConveyorLogic / SplitterLogic）から読む。

@export var show_line: bool = true

var _line: Line2D = null
var _input_direction: int = -1

@onready var _piece: Piece = get_parent()
@onready var _mover: Node = _find_mover()
@onready var _item_icon: Sprite2D = $ItemIcon


func _ready():
	# 描画レイヤー: コンベア上のアイテムは土台(5)・ライン(6)より手前（7）。
	# ライン(_line)と対でここに集約し、シーン側設定への分散を避ける。
	_item_icon.z_index = 7
	_item_icon.z_as_relative = false
	_piece.shape_changed.connect(refresh_line)
	refresh_line()


func _find_mover() -> Node:
	for sibling in get_parent().get_children():
		if sibling.has_method("get_held_item"):
			return sibling
	return null


func _process(_delta: float):
	update_item_icon()


func set_input_direction(direction: int):
	_input_direction = direction
	refresh_line()


func refresh_line():
	if _line:
		_line.queue_free()
		_line = null
	if not show_line:
		return
	var ports = _piece.get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = _input_direction if _input_direction >= 0 else (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	_line = Line2D.new()
	# 描画レイヤー: ベルトの接続を示すUI線は土台(5)とアイテム(7)の間（6）。
	_line.z_index = 6
	_line.z_as_relative = false
	_line.add_point(in_edge)
	_line.add_point(Vector2.ZERO)
	_line.add_point(out_edge)
	_line.width = 10.0
	_line.default_color = Color(0.9, 0.85, 0.6, 0.9)
	add_child(_line)


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
	_item_icon.position = _item_position_on_line()


func _item_position_on_line() -> Vector2:
	if not _line or _line.get_point_count() < 3:
		return Vector2.ZERO
	var t = _mover.get_progress_ratio()
	var in_edge = _line.get_point_position(0)
	var center = _line.get_point_position(1)
	var out_edge = _line.get_point_position(2)
	if t < 0.5:
		return in_edge.lerp(center, t * 2.0)
	return center.lerp(out_edge, (t - 0.5) * 2.0)
