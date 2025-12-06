class_name Main
extends Node2D

const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const PiecePlacerScript = preload("res://scenes/components/piece_placer/piece_placer.gd")

@onready var hud: HUD = $HUD
@onready var grid_manager:= $GridManager
@onready var piece_placer = $PiecePlacer

var palette: Palette

# テスト互換性のためのプロパティアクセサ
var current_piece_shape: Array[Hex]:
	get:
		return piece_placer.current_piece_shape

func _init():
	palette = PaletteScript.new()

func _ready():
	grid_manager.create_hex_grid(grid_manager.grid_radius)
	hud.setup_ui(palette)
	piece_placer.setup(grid_manager, palette)

func _unhandled_input(event):
	_handle_key_input(event)
	_handle_mouse_motion(event)
	_handle_mouse_click(event)

func _handle_key_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index = event.keycode - KEY_1
			palette.select_slot(index)
		elif event.keycode == KEY_R:
			piece_placer.rotate_current_piece()

func _handle_mouse_motion(event):
	if event is InputEventMouseMotion:
		var local_mouse_pos = make_input_local(event).position
		piece_placer.update_hover(local_mouse_pos)

func _handle_mouse_click(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		piece_placer.place_current_piece()

func place_selected_piece(target_hex: Hex) -> bool:
	return piece_placer.place_piece_at_hex(target_hex)

func rotate_current_piece():
	piece_placer.rotate_current_piece()

func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	return piece_placer._get_rotated_piece_shape(original_shape)
