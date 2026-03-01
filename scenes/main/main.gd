class_name Main
extends Node2D

@onready var hud: HUD = $HUD
@onready var island: Island = $Island
@onready var piece_placer: PiecePlacer = $PiecePlacer


func _ready():
	island.create_hex_grid(island.grid_radius)
	piece_placer.setup(island)


func _on_hud_slot_selected(piece_data: PieceData):
	piece_placer.select_piece(piece_data)


func _unhandled_input(event):
	_handle_key_input(event)
	_handle_mouse_motion(event)
	_handle_mouse_click(event)


func _handle_key_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_T:
			island.toggle_detail_mode()
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
			if hud.get_active_index() != -1:  # ツールバーで何かを選択中なら
				hud.deselect()  # まず選択を解除する
			elif piece_placer.current_hovered_hex != null:
				# 何も選択していないなら、グリッド上のピースを削除する
				island.remove_piece_at(piece_placer.current_hovered_hex)
