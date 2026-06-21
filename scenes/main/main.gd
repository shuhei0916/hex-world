class_name Main
extends Node2D

enum Mode { LOCAL, WORLD_MAP }

var _mode: Mode = Mode.LOCAL

@onready var hud: HUD = $HUD
@onready var world: World = $World
@onready var world_map_view: WorldMapView = $WorldMapView
@onready var piece_placer: PiecePlacer = $PiecePlacer
@onready var sfx_player: SfxPlayer = $SfxPlayer


func _ready():
	world.create_chunk(Hex.new(0, 0))
	world.create_chunk(Hex.new(1, 0))
	world.create_chunk(Hex.new(-1, 0))
	world.create_chunk(Hex.new(0, 1))
	var initial_chunk = world.get_chunk(Hex.new(0, 0))
	var goal = HubGoals.get_current_goal()
	initial_chunk.place_hub(goal["goal_item"], goal["required"])
	initial_chunk.generate_ore_deposits(5)
	_activate_chunk(Hex.new(0, 0))
	hud.slot_selected.connect(sfx_player.on_slot_selected)
	piece_placer.conveyor_path_extended.connect(sfx_player.on_conveyor_path_extended)


func is_local_mode() -> bool:
	return _mode == Mode.LOCAL


func _on_hud_slot_selected(scene: PackedScene):
	piece_placer.select_piece(scene)


func _unhandled_input(event):
	_handle_key_input(event)
	_handle_mouse_motion(event)
	_handle_mouse_click(event)


func _handle_key_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SPACE:
			_toggle_mode()
		elif event.is_action_pressed("rotate_piece") and is_local_mode():
			piece_placer.rotate_current_piece()


func _toggle_mode():
	if _mode == Mode.LOCAL:
		_enter_world_map_mode()
	else:
		_enter_local_mode()


func _activate_chunk(chunk_hex: Hex) -> void:
	var prev = world.get_active_chunk()
	if prev:
		if prev.piece_placed.is_connected(sfx_player.on_piece_placed):
			prev.piece_placed.disconnect(sfx_player.on_piece_placed)
		if prev.piece_removed.is_connected(sfx_player.on_piece_removed):
			prev.piece_removed.disconnect(sfx_player.on_piece_removed)
	world.set_active_chunk(chunk_hex)
	var chunk = world.get_active_chunk()
	piece_placer.setup(chunk)
	chunk.piece_placed.connect(sfx_player.on_piece_placed)
	chunk.piece_removed.connect(sfx_player.on_piece_removed)


func _enter_world_map_mode():
	_mode = Mode.WORLD_MAP
	world.visible = false
	world_map_view.visible = true
	world_map_view.setup(world)
	if world.get_active_hex() != null:
		world_map_view.set_active_chunk(world.get_active_hex())


func _enter_local_mode():
	_mode = Mode.LOCAL
	world.visible = true
	world_map_view.visible = false


func _handle_mouse_motion(event):
	if event is InputEventMouseMotion and is_local_mode():
		var local_mouse_pos = make_input_local(event).position
		piece_placer.update_hover(local_mouse_pos)


func _handle_mouse_click(event):
	if not event is InputEventMouseButton:
		return
	if _mode == Mode.WORLD_MAP:
		_handle_world_map_click(event)
	else:
		_handle_local_click(event)


func _handle_world_map_click(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = make_input_local(event).position
		var view_pos = world_map_view.to_local(to_global(local_pos))
		var hex = world_map_view.chunk_at_local_pos(view_pos)
		if hex != null:
			_activate_chunk(hex)
			world_map_view.set_active_chunk(hex)
			_enter_local_mode()


func _handle_local_click(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			piece_placer.start_drag()
			piece_placer.place_current_piece()
		else:
			piece_placer.stop_drag()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if hud.get_active_index() != -1:
				hud.deselect()
			else:
				piece_placer.start_delete_drag()
		else:
			piece_placer.stop_delete_drag()
