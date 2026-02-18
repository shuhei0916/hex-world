class_name HUD
extends CanvasLayer

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

var piece_placer: PiecePlacer

# スロットに割り当てるピースタイプの定義
var _assignments: Array = [
	PieceData.Type.BEE,
	PieceData.Type.WORM,
	PieceData.Type.WAVE,
	PieceData.Type.PISTOL,
	PieceData.Type.BAR,
	PieceData.Type.PROPELLER,
	PieceData.Type.ARCH,
	PieceData.Type.CHEST
]

@onready var toolbar: HBoxContainer = $ToolBar
@onready var slot_buttons: Array = $ToolBar.get_children()


func _ready():
	_initialize_toolbar()


func setup(piece_placer_ref: PiecePlacer):
	piece_placer = piece_placer_ref


func _initialize_toolbar():
	for i in slot_buttons.size():
		var btn = slot_buttons[i] as Button
		var piece_data = get_piece_data_for_slot(i)
		if piece_data:
			_create_piece_icon(btn, piece_data)


func on_slot_pressed(index: int):
	if index < 0 or index >= slot_buttons.size():
		_deselect_all_buttons()
		_deselect_piece()
		return

	var btn = slot_buttons[index]
	if btn.button_pressed:
		_select_piece(index)
	else:
		_deselect_piece()


func _select_piece(index: int):
	if piece_placer:
		var data = get_piece_data_for_slot(index)
		piece_placer.select_piece(data)


func _deselect_piece():
	if piece_placer:
		piece_placer.select_piece(null)


func _deselect_all_buttons():
	var group = _get_button_group()
	if group and group.get_pressed_button():
		group.get_pressed_button().button_pressed = false


func get_piece_data_for_slot(index: int) -> PieceData:
	if index < 0 or index >= _assignments.size():
		return null
	return PieceData.get_data(_assignments[index])


func _create_piece_icon(parent: Control, piece_data: PieceData):
	# 既存のアイコンがあれば削除
	for child in parent.get_children():
		if child.name == "IconRoot":
			child.queue_free()

	var icon_root = Node2D.new()
	icon_root.name = "IconRoot"
	icon_root.position = parent.custom_minimum_size / 2.0
	icon_root.scale = Vector2(0.15, 0.15)
	parent.add_child(icon_root)

	var shape = piece_data.shape
	var color = piece_data.color
	var layout = Layout.new(Layout.layout_pointy, Vector2(42, 42), Vector2(0, 0))

	for hex in shape:
		var tile = HexTileScene.instantiate()
		icon_root.add_child(tile)
		tile.position = Layout.hex_to_pixel(layout, hex)
		tile.setup_hex(hex)
		tile.set_color(color)


func get_active_index() -> int:
	var group = _get_button_group()
	if not group:
		return -1
	var pressed_btn = group.get_pressed_button()
	return pressed_btn.get_index() if pressed_btn else -1


func _get_button_group() -> ButtonGroup:
	if not slot_buttons.is_empty():
		return (slot_buttons[0] as Button).button_group
	return null
