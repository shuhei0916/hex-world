class_name Main
extends Node2D

const PLANET_RADIUS := 4
# 新しいゲームは毎回同じ惑星で始める（シードの選択は未実装）
const PLANET_SEED := 2026
# ローカル画面でこれより引くとワールドマップへ移る。ワールドマップでローカル画面の
# この倍率に相当するところまで寄せるとローカル画面へ入る（差をつけて行き来のちらつきを防ぐ）
const LOCAL_TO_MAP_ZOOM := 0.45
const MAP_TO_LOCAL_ZOOM := 0.6

# ワールドマップから戻ったときに復元する、ローカルモードでのカメラ位置
var _local_camera_position := Vector2.ZERO

@onready var hud: HUD = $HUD
@onready var world: World = $World
@onready var world_map_view: WorldMapView = $WorldMapView
@onready var piece_placer: PiecePlacer = $PiecePlacer
@onready var sfx_player: SfxPlayer = $SfxPlayer
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var camera: CameraController = $CameraController
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready():
	if not _load_game():
		_start_new_game()
	_activate_chunk(world.get_active_hex())
	hud.slot_selected.connect(sfx_player.on_slot_selected)
	piece_placer.conveyor_path_extended.connect(sfx_player.on_conveyor_path_extended)
	pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	hud.modal_changed.connect(_on_hud_modal_changed)
	piece_placer.placement_denied.connect(_on_placement_denied)
	pause_menu.save_requested.connect(_on_pause_menu_save_requested)
	pause_menu.new_game_requested.connect(_on_pause_menu_new_game_requested)


func _start_new_game() -> void:
	world.setup_planet(Planet.new(PLANET_RADIUS, PLANET_SEED))
	var initial_chunk = world.create_chunk(Hex.new(0, 0))
	var goal = HubGoals.get_current_goal()
	initial_chunk.place_hub(goal["goal_item"], goal["required"])
	world.set_active_chunk(Hex.new(0, 0))


# セーブデータがあれば復元して true を返す。無い・壊れている場合は false。
func _load_game() -> bool:
	var data = SaveGame.read()
	if data.get("chunks", []).is_empty() or not data.has("active_chunk"):
		return false
	SaveGame.apply(world, data, HubGoals)
	# HUD は Main より先に初期化されるので、復元した解放状況を反映させる
	HubGoals.unlocks_changed.emit()
	return true


func save_game() -> bool:
	return SaveGame.write(SaveGame.path, SaveGame.capture(world, HubGoals))


# セーブデータと進行度を捨てる（シーンの再読み込みは呼び出し側で行う）
func discard_progress() -> void:
	SaveGame.delete()
	HubGoals.reset()


func _on_pause_menu_save_requested() -> void:
	pause_menu.show_status("セーブしました" if save_game() else "セーブに失敗しました")


func _on_pause_menu_new_game_requested() -> void:
	discard_progress()
	get_tree().paused = false
	get_tree().reload_current_scene()


# 在庫不足で設置できなかった理由を、マウスカーソルの近くに出す
func _on_placement_denied(message: String) -> void:
	hud.show_cursor_message(message, get_viewport().get_mouse_position())


# 研究画面などを開いている間は、ホイールを一覧のスクロールに使うのでマップは拡縮しない
func _on_hud_modal_changed() -> void:
	camera.zoom_enabled = not hud.is_modal_open()


func _on_pause_menu_quit_requested() -> void:
	get_tree().quit()


func _process(_delta: float) -> void:
	update_navigation()


# カメラの位置と倍率に合わせて、今いる chunk とローカル画面／ワールドマップを切り替える
func update_navigation() -> void:
	if is_local_mode():
		_follow_camera_chunk()
		if camera.zoom.x < LOCAL_TO_MAP_ZOOM:
			_zoom_out_to_world_map()
	elif camera.zoom.x * _map_to_local_scale() > MAP_TO_LOCAL_ZOOM:
		_zoom_in_to_local()


# ワールドマップの長さをローカル画面の長さに直す倍率
func _map_to_local_scale() -> float:
	return world_map_view.get_tile_spacing() / world.get_chunk_spacing()


# パンで隣の chunk の中心の方が近くなったら、その chunk を今いる chunk にする。
# 新しい chunk は原点に来るので、カメラも同じだけずらして見え方を保つ
func _follow_camera_chunk() -> void:
	if piece_placer.is_dragging or piece_placer.is_delete_dragging:
		return
	var nearest = world.get_nearest_visible_chunk(camera.position)
	if nearest == null or Hex.equals(nearest, world.get_active_hex()):
		return
	var offset = world.get_chunk(nearest).position
	_activate_chunk(nearest)
	camera.position -= offset


# 見え方を保ったままワールドマップへ移る
func _zoom_out_to_world_map() -> void:
	var local_position = camera.position
	var local_zoom = camera.zoom.x
	_enter_world_map_mode()
	var scale = _map_to_local_scale()
	var tile = world_map_view.get_tile_position(world.get_active_hex())
	camera.position = world_map_view.to_global(tile + local_position * scale)
	camera.zoom = Vector2.ONE * (local_zoom / scale)


# 画面中央の chunk のローカル画面へ、見え方を保ったまま入る
func _zoom_in_to_local() -> void:
	var map_position = world_map_view.to_local(camera.position)
	var chunk_hex = world_map_view.chunk_at_local_pos(map_position)
	if chunk_hex == null:
		return
	var scale = _map_to_local_scale()
	var map_zoom = camera.zoom.x
	_handle_world_map_chunk_selected(chunk_hex)
	camera.position = (map_position - world_map_view.get_tile_position(chunk_hex)) / scale
	camera.zoom = Vector2.ONE * (map_zoom * scale)


func is_local_mode() -> bool:
	return world.visible


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
		elif event.keycode == KEY_F2:
			debug_overlay.toggle()
			_refresh_debug_overlay()
		elif event.keycode == KEY_F3:
			HubGoals.toggle_creative_mode()
		elif event.is_action_pressed("rotate_piece") and is_local_mode():
			piece_placer.rotate_current_piece()
		elif event.keycode == KEY_T and is_local_mode():
			hud.cycle_variant()
		elif event.keycode == KEY_E and is_local_mode():
			hud.toggle_research_panel()


func _toggle_mode():
	if is_local_mode():
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
	hud.set_chunk_coordinate(chunk_hex)
	_refresh_debug_overlay()
	chunk.piece_placed.connect(sfx_player.on_piece_placed)
	chunk.piece_removed.connect(sfx_player.on_piece_removed)


func _enter_world_map_mode():
	hud.show_hovered_piece(null)
	world.visible = false
	hud.visible = false
	piece_placer.visible = false
	world_map_view.visible = true
	world_map_view.setup(world)
	if world.get_active_hex() != null:
		world_map_view.set_active_chunk(world.get_active_hex())
	world_map_view.refresh_connections(world.get_connected_chunk_pairs())
	_local_camera_position = camera.position
	if world.get_active_hex() != null:
		var tile_pos = world_map_view.get_tile_position(world.get_active_hex())
		camera.position = world_map_view.to_global(tile_pos)
	_refresh_debug_overlay()


func _enter_local_mode():
	world.visible = true
	hud.visible = true
	piece_placer.visible = true
	world_map_view.visible = false
	camera.position = _local_camera_position
	_refresh_debug_overlay()


# デバッグ表示の内容は現在のモードだけで決まるようここに一元化する
func _refresh_debug_overlay():
	if not debug_overlay or not debug_overlay.visible:
		return
	if is_local_mode():
		debug_overlay.refresh(world.get_active_chunk())
	else:
		debug_overlay.refresh_world_map(world_map_view, world.get_map_hexes())


func _handle_mouse_motion(event):
	if not event is InputEventMouseMotion:
		return
	if is_local_mode():
		_hover_local(make_input_local(event).position)
	else:
		var local_pos = make_input_local(event).position
		var view_pos = world_map_view.to_local(to_global(local_pos))
		world_map_view.set_hovered_chunk(world_map_view.chunk_at_local_pos(view_pos))


func _hover_local(local_mouse_pos: Vector2) -> void:
	piece_placer.update_hover(local_mouse_pos)
	# 周りに描いている隣の chunk の施設も、情報だけは見られるようにする
	hud.show_hovered_piece(world.get_piece_at_position(local_mouse_pos))


func _handle_mouse_click(event):
	if not event is InputEventMouseButton:
		return
	if is_local_mode():
		_handle_local_click(event)
	else:
		_handle_world_map_click(event)


func _handle_world_map_click(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = make_input_local(event).position
		var view_pos = world_map_view.to_local(to_global(local_pos))
		var hex = world_map_view.chunk_at_local_pos(view_pos)
		if hex != null:
			_handle_world_map_chunk_selected(hex)


func _handle_world_map_chunk_selected(hex: Hex) -> void:
	_activate_chunk(hex)
	world_map_view.set_active_chunk(hex)
	_enter_local_mode()


func _handle_local_click(event: InputEventMouseButton) -> void:
	# 研究画面などを開いている間の盤面クリックは、画面を閉じるだけで盤面には作用させない
	if hud.is_modal_open():
		if event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			hud.close_modals()
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _open_item_picker_at_cursor():
			return
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


# 設置するピースを選んでいない状態で搬出チェストをクリックしたら、取り出すアイテムを選ぶ
func _open_item_picker_at_cursor() -> bool:
	if hud.get_active_index() != -1 or piece_placer.current_hovered_hex == null:
		return false
	var piece = world.get_active_chunk().get_piece_at_hex(piece_placer.current_hovered_hex)
	if piece == null or piece.get_node_or_null("ChestOutput") == null:
		return false
	hud.open_item_picker(piece)
	return true
