class_name HUD
extends CanvasLayer

signal slot_selected(piece_data: PieceData)

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# スロットに割り当てるピースタイプの定義
var _assignments: Array[PieceData.Type] = [
	PieceData.Type.MINER,
	PieceData.Type.SMELTER,
	PieceData.Type.ASSEMBLER,
	PieceData.Type.CUTTER,
	PieceData.Type.CONVEYOR,
	PieceData.Type.MIXER,
	PieceData.Type.PAINTER,
	PieceData.Type.CHEST
]

@onready var toolbar: HBoxContainer = $ToolBar
@onready var slot_buttons: Array = $ToolBar.get_children()
@onready var _button_group: ButtonGroup = (
	(slot_buttons[0] as Button).button_group if not slot_buttons.is_empty() else null
)


func _ready():
	_initialize_toolbar()


func _initialize_toolbar():
	for i in slot_buttons.size():
		var btn = slot_buttons[i] as Button
		var piece_data = get_piece_data_for_slot(i)
		if piece_data:
			_create_piece_icon(btn, piece_data)


func on_slot_pressed(index: int):
	if index < 0 or index >= slot_buttons.size():
		_deselect_all_buttons()
		slot_selected.emit(null)
		return

	var btn = slot_buttons[index]
	if btn.button_pressed:
		var data = get_piece_data_for_slot(index)
		if data:
			print("selected: ", PieceData.Type.keys()[data.piece_type])
		slot_selected.emit(data)
	else:
		slot_selected.emit(null)


func _deselect_all_buttons():
	if _button_group and _button_group.get_pressed_button():
		_button_group.get_pressed_button().button_pressed = false


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


func deselect():
	_deselect_all_buttons()
	slot_selected.emit(null)


func get_active_index() -> int:
	if not _button_group:
		return -1
	var pressed_btn = _button_group.get_pressed_button()
	return pressed_btn.get_index() if pressed_btn else -1
