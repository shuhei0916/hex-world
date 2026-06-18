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
	world.set_active_chunk(Hex.new(0, 0))
	var chunk = world.get_active_chunk()
	piece_placer.setup(chunk)
	chunk.place_hub("iron_plate", 10)
	chunk.generate_ore_deposits(5)
	# 効果音の接続は初期配置の後に行う（起動時に設置音が鳴るのを防ぐ）
	chunk.piece_placed.connect(sfx_player.on_piece_placed)
	chunk.piece_removed.connect(sfx_player.on_piece_removed)
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


func _enter_world_map_mode():
	_mode = Mode.WORLD_MAP
	world.visible = false
	world_map_view.visible = true
	world_map_view.setup(world)
	world_map_view.set_active_chunk(world.get_chunk_hexes()[0])


func _enter_local_mode():
	_mode = Mode.LOCAL
	world.visible = true
	world_map_view.visible = false


func _handle_mouse_motion(event):
	if event is InputEventMouseMotion and is_local_mode():
		var local_mouse_pos = make_input_local(event).position
		piece_placer.update_hover(local_mouse_pos)


func _handle_mouse_click(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				piece_placer.start_drag()
				piece_placer.place_current_piece()
			else:
				piece_placer.stop_drag()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if hud.get_active_index() != -1:  # ツールバーで何かを選択中なら
					hud.deselect()  # まず選択を解除する
				else:
					# 何も選択していないなら削除ドラッグ開始（ホバー中のピースも即削除）
					piece_placer.start_delete_drag()
			else:
				piece_placer.stop_delete_drag()
