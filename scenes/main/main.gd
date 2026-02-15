class_name Main
extends Node2D

@onready var hud: HUD = $HUD
@onready var grid_manager: GridManager = $GridManager
@onready var piece_placer: PiecePlacer = $PiecePlacer
@onready var ghost_preview_container = $PiecePlacer/GhostPreviewContainer
@onready var mouse_preview_container = $PiecePlacer/MousePreviewContainer


func _ready():
	grid_manager.create_hex_grid(grid_manager.grid_radius)

	hud.setup(piece_placer)
	piece_placer.setup(grid_manager, mouse_preview_container, ghost_preview_container)


func _unhandled_input(event):
	_handle_key_input(event)
	_handle_mouse_motion(event)
	_handle_mouse_click(event)


func _handle_key_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var index = event.keycode - KEY_1

			hud.select_slot(index)

		elif event.keycode == KEY_T:
			grid_manager.toggle_detail_mode()

		elif event.is_action_pressed("rotate_piece"):
			piece_placer.rotate_current_piece()


func _handle_mouse_motion(event):
	if event is InputEventMouseMotion:
		var local_mouse_pos = make_input_local(event).position

		piece_placer.update_hover(local_mouse_pos)


func _handle_mouse_click(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			piece_placer.place_current_piece()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if piece_placer.selected_piece_data != null:
				hud.select_slot(-1)

			elif piece_placer.current_hovered_hex != null:
				piece_placer.remove_piece_at_hex(piece_placer.current_hovered_hex)


func place_selected_piece(target_hex: Hex) -> bool:
	return piece_placer.place_piece_at_hex(target_hex)


func rotate_current_piece():
	piece_placer.rotate_current_piece()


func _get_rotated_piece_shape(original_shape: Array[Hex]) -> Array[Hex]:
	return piece_placer._get_rotated_piece_shape(original_shape)
