class_name HUD
extends CanvasLayer

signal slot_selected(scene: PackedScene)

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")
const ASSEMBLER_SCENE = preload("res://scenes/components/piece/assembler.tscn")
const CUTTER_SCENE = preload("res://scenes/components/piece/cutter.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const MIXER_SCENE = preload("res://scenes/components/piece/mixer.tscn")
const PAINTER_SCENE = preload("res://scenes/components/piece/painter.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")

var _scenes: Array[PackedScene] = [
	MINER_SCENE,
	SMELTER_SCENE,
	ASSEMBLER_SCENE,
	CUTTER_SCENE,
	CONVEYOR_SCENE,
	MIXER_SCENE,
	PAINTER_SCENE,
	CHEST_SCENE,
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
		var scene = get_scene_for_slot(i)
		if scene:
			_create_piece_icon(btn, scene)


func on_slot_pressed(index: int):
	if index < 0 or index >= slot_buttons.size():
		_deselect_all_buttons()
		slot_selected.emit(null)
		return

	var btn = slot_buttons[index]
	if btn.button_pressed:
		var scene = get_scene_for_slot(index)
		if scene:
			var piece = scene.instantiate()
			print("selected: ", PieceData.Type.keys()[piece.piece_type])
			piece.free()
		slot_selected.emit(scene)
	else:
		slot_selected.emit(null)


func _deselect_all_buttons():
	if _button_group and _button_group.get_pressed_button():
		_button_group.get_pressed_button().button_pressed = false


func get_scene_for_slot(index: int) -> PackedScene:
	if index < 0 or index >= _scenes.size():
		return null
	return _scenes[index]


func _create_piece_icon(parent: Control, scene: PackedScene):
	# 既存のアイコンがあれば削除
	for child in parent.get_children():
		if child.name == "IconRoot":
			child.queue_free()

	var piece = scene.instantiate()
	var shape = piece.get_hex_shape()
	var color = piece.piece_color
	piece.free()

	var icon_root = Node2D.new()
	icon_root.name = "IconRoot"
	icon_root.position = parent.custom_minimum_size / 2.0
	icon_root.scale = Vector2(0.15, 0.15)
	parent.add_child(icon_root)

	var layout = Layout.make_default()

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
