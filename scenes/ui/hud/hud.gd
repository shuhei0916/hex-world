class_name HUD
extends CanvasLayer

signal slot_selected(scene: PackedScene)

const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter.tscn")
const ASSEMBLER_SCENE = preload("res://scenes/components/piece/assembler.tscn")
const CUTTER_SCENE = preload("res://scenes/components/piece/cutter.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const MIXER_SCENE = preload("res://scenes/components/piece/mixer.tscn")
const PAINTER_SCENE = preload("res://scenes/components/piece/painter.tscn")
const BALANCER_SCENE = preload("res://scenes/components/piece/balancer.tscn")

var _scenes: Array[PackedScene] = [
	CONVEYOR_SCENE,
	BALANCER_SCENE,
	MINER_SCENE,
	SMELTER_SCENE,
	ASSEMBLER_SCENE,
	CUTTER_SCENE,
	MIXER_SCENE,
	PAINTER_SCENE,
]

@onready var toolbar: HBoxContainer = $ToolBar
@onready var slot_buttons: Array = $ToolBar.get_children()
@onready var info_panel: PieceInfoPanel = $PieceInfoPanel
@onready var _button_group: ButtonGroup = (
	(slot_buttons[0] as Button).button_group if not slot_buttons.is_empty() else null
)


func _ready():
	info_panel.clear()
	slot_selected.connect(_on_slot_selected_for_info)


func _on_slot_selected_for_info(scene: PackedScene):
	if scene == null:
		info_panel.clear()
		return
	var piece = scene.instantiate()
	info_panel.show_info(
		piece.piece_name, piece.piece_description, _rate_text_for_type(piece.piece_type)
	)
	piece.free()


# ピース種別の基準速度（個/分）を表示用テキストにする。速度を持たないピースは空文字。
func _rate_text_for_type(piece_type: PieceData.Type) -> String:
	var rate = _items_per_minute_for_type(piece_type)
	if rate <= 0.0:
		return ""
	return "スピード: %d/分" % roundi(rate)


# 機械はレシピの基準速度、搬送系(コンベア/バランサー)は TransferBuffer の搬送間隔から算出。
func _items_per_minute_for_type(piece_type: PieceData.Type) -> float:
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if not recipes.is_empty():
		return recipes[0].items_per_minute()
	if piece_type == PieceData.Type.CONVEYOR or piece_type == PieceData.Type.BALANCER:
		return 60.0 / TransferBuffer.TRANSFER_TIME
	return 0.0


func on_slot_pressed(index: int):
	if index < 0 or index >= slot_buttons.size():
		_deselect_all_buttons()
		slot_selected.emit(null)
		return

	var btn = slot_buttons[index]
	if btn.button_pressed:
		slot_selected.emit(get_scene_for_slot(index))
	else:
		slot_selected.emit(null)


func _deselect_all_buttons():
	if _button_group and _button_group.get_pressed_button():
		_button_group.get_pressed_button().button_pressed = false


func get_scene_for_slot(index: int) -> PackedScene:
	if index < 0 or index >= _scenes.size():
		return null
	return _scenes[index]


func deselect():
	_deselect_all_buttons()
	slot_selected.emit(null)


func get_active_index() -> int:
	if not _button_group:
		return -1
	var pressed_btn = _button_group.get_pressed_button()
	return pressed_btn.get_index() if pressed_btn else -1
