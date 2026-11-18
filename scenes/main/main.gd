class_name Main
extends Node2D

const PLANET_RADIUS := 4
# 新しいゲームは毎回同じ惑星で始める（シードの選択は未実装）
const PLANET_SEED := 2026
# ローカル画面でこれより引くとワールドマップへ移る。ワールドマップでローカル画面の
# この倍率に相当するところまで寄せるとローカル画面へ入る（差をつけて行き来のちらつきを防ぐ）
const LOCAL_TO_MAP_ZOOM := 0.45
const MAP_TO_LOCAL_ZOOM := 0.6
# 戦闘を始めたときのカメラは、chunk 全体が画面の下に並ぶスキルのボタンに隠れずに映る位置と倍率
# （battle_camera_view）にする。そこからは建築のときと同じ操作で動かせる。
# 画面の下でスキルのボタンが占める高さと、上下左右に空ける余白（画面のピクセル）
const BATTLE_BOTTOM_RESERVED := 100.0
const BATTLE_MARGIN := 16.0
# 戦闘中に引ける限界（chunk 全体が収まる倍率の方が小さければ、そこまで）
const BATTLE_MIN_ZOOM := 0.5
# キャラクターの歩く速さ（ピクセル/秒）。マス3つ半ほど
const WALK_SPEED := 260.0
# カメラがキャラクターに追いつく速さ（1秒あたり、残りの距離の何割を詰めるかの目安）。
# 一瞬で合わせると、離れているときにかくつくので、少しずつ近づける
const CAMERA_FOLLOW_RATE := 10.0
# chunk の端に立って押すと、辺の向こうの隣の chunk へ渡るキー
const CROSS_KEY := KEY_F
# どこからも届かないマス（キャラクターのいない chunk の建築できる範囲の中心にする）
const UNREACHABLE_HEX := Vector2i(1 << 20, 1 << 20)

# ワールドマップから戻ったときに復元する、ローカルモードでのカメラ位置
var _local_camera_position := Vector2.ZERO
# いま戦って解放しようとしている chunk。戦闘中でなければ null
var _battle_chunk_hex = null
# 戦闘を始める前の状態。負けたり撤退したりしたら、ここへ戻る
var _pre_battle := {}
# いまの戦闘。勝ったとき、主人公が戦い終えたマスにキャラクターを立たせるのに使う
var _battle_turn: SkillTurn = null
# true の間、カメラはキャラクターへ少しずつ近づく（歩いたときや戦闘のあと）。追いついたら止まる
var _camera_following := false
# カメラの倍率も少しずつ近づけるときの目標。null なら倍率は変えない
var _camera_target_zoom = null

@onready var hud: HUD = $HUD
@onready var world: World = $World
@onready var world_map_view: WorldMapView = $WorldMapView
@onready var piece_placer: PiecePlacer = $PiecePlacer
@onready var sfx_player: SfxPlayer = $SfxPlayer
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var camera: CameraController = $CameraController
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var battle_overlay: BattleOverlay = $BattleOverlay


func _ready():
	# 研究の条件（chunk の数・バイオーム）のため、所有している chunk を HubGoals に伝え続ける
	world.territory.changed.connect(_sync_owned_chunks)
	if not _load_game():
		_start_new_game()
	_sync_owned_chunks()
	_activate_chunk(world.get_active_hex())
	# 新しいゲームと、キャラクターの記録が無い旧セーブでは、今いる chunk のハブの隣に立たせる
	if world.player == null:
		var active_hex = world.get_active_hex()
		world.place_player(active_hex, PlayerCharacter.spawn_hex(world.get_chunk(active_hex)))
	_refresh_camera_keyboard()
	camera.position = world.get_player_position()
	hud.slot_selected.connect(sfx_player.on_slot_selected)
	piece_placer.conveyor_path_extended.connect(sfx_player.on_conveyor_path_extended)
	pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	hud.modal_changed.connect(_on_hud_modal_changed)
	piece_placer.placement_denied.connect(_on_placement_denied)
	pause_menu.save_requested.connect(_on_pause_menu_save_requested)
	pause_menu.new_game_requested.connect(_on_pause_menu_new_game_requested)
	battle_overlay.closed.connect(_on_battle_closed)


func _start_new_game() -> void:
	world.setup_planet(Planet.new(PLANET_RADIUS, PLANET_SEED))
	var initial_chunk = world.create_chunk(Vector2i(0, 0))
	var goal = HubGoals.get_current_goal()
	initial_chunk.place_hub(goal["goal_item"], goal["required"])
	world.territory.claim(Vector2i(0, 0))
	world.set_active_chunk(Vector2i(0, 0))


func _sync_owned_chunks() -> void:
	HubGoals.set_owned_chunks(world.territory.count_by_biome())


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
	# 戦闘中は解放前の chunk に入っているので、今いる chunk は戦闘前のものとして保存する
	var active_hex = _pre_battle.get("active_hex")
	return SaveGame.write(SaveGame.path, SaveGame.capture(world, HubGoals, active_hex))


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


func _process(delta: float) -> void:
	update_navigation()
	update_walk(_read_walk_input(), delta)
	update_camera_follow(delta)
	world.set_player_prompt(crossing_prompt() if _can_walk() else "")
	_sync_reach()


func _read_walk_input() -> Vector2:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input.y -= 1
	if Input.is_key_pressed(KEY_S):
		input.y += 1
	if Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_D):
		input.x += 1
	return input


# 押している方向 input へ、WALK_SPEED の速さでキャラクターを歩かせ、カメラで追う。
# 建築の画面でだけ歩き、ワールドマップ・戦闘中・研究画面などでは歩かない
func update_walk(input: Vector2, delta: float) -> void:
	if input == Vector2.ZERO or not _can_walk():
		return
	if world.move_player_by(input.normalized() * WALK_SPEED * delta):
		_camera_following = true


# キャラクターが chunk の辺に立っていれば、辺の向こうの隣の chunk へ渡る。
# 所有している chunk ならそのまま入り、所有していない隣なら、入ってきたマスから戦って解放する
func try_cross() -> void:
	if not _can_walk():
		return
	var crossing = world.get_player_crossing()
	if crossing.is_empty():
		return
	var target: Vector2i = crossing["chunk_hex"]
	if world.territory.is_owned(target):
		# 渡った先の chunk は原点に来るので、カメラも同じだけずらしてからキャラクターを追う
		var offset = world.get_chunk(target).position
		if world.cross_player():
			_activate_chunk(target)
			camera.position -= offset
			_camera_following = true
	elif world.territory.can_challenge(target):
		start_battle(target, crossing["hex"])


# 建築できるのは、今いる chunk に立っているキャラクターの近くだけ
func _sync_reach() -> void:
	var player = world.player
	if player != null and player.chunk_hex == world.get_active_hex():
		piece_placer.reach_center = player.hex
	else:
		# キャラクターのいない chunk では、どこにも届かない
		piece_placer.reach_center = UNREACHABLE_HEX


# キャラクターの立っている辺から、隣の chunk へ渡れるときの案内。渡れなければ空
func crossing_prompt() -> String:
	var crossing = world.get_player_crossing()
	if crossing.is_empty():
		return ""
	var key = OS.get_keycode_string(CROSS_KEY)
	if world.territory.is_owned(crossing["chunk_hex"]):
		return "[%s] 渡る" % key
	if world.territory.can_challenge(crossing["chunk_hex"]):
		return "[%s] 戦って解放" % key
	return ""


func _can_walk() -> bool:
	return is_local_mode() and not battle_overlay.is_open() and not hud.is_modal_open()


# カメラをキャラクター（と目標の倍率）へ少しずつ近づける。追いついたら止まり、
# 止まっている間は中ボタンのドラッグなどで自由に動かせる
func update_camera_follow(delta: float) -> void:
	if not _camera_following:
		return
	if not is_local_mode() or battle_overlay.is_open():
		_stop_camera_follow()
		return
	var weight = 1.0 - exp(-CAMERA_FOLLOW_RATE * delta)
	var target = world.get_player_position()
	camera.position = camera.position.lerp(target, weight)
	var zoom_done = true
	if _camera_target_zoom != null:
		var target_zoom = Vector2.ONE * _camera_target_zoom
		camera.zoom = camera.zoom.lerp(target_zoom, weight)
		zoom_done = camera.zoom.distance_to(target_zoom) < 0.001
		if zoom_done:
			camera.zoom = target_zoom
	if camera.position.distance_to(target) < 0.5 and zoom_done:
		camera.position = target
		_stop_camera_follow()


func _stop_camera_follow() -> void:
	_camera_following = false
	_camera_target_zoom = null


# WASD は、キャラクターが歩く建築の画面ではカメラを動かさず、ワールドマップと戦闘中はカメラを動かす
func _refresh_camera_keyboard() -> void:
	camera.keyboard_move_enabled = not is_local_mode() or battle_overlay.is_open()


# カメラの倍率に合わせて、ローカル画面／ワールドマップを切り替える
func update_navigation() -> void:
	# 戦闘のあと倍率を戻している途中は、引いた倍率のまま地図へ切り替えない
	if battle_overlay.is_open() or _camera_target_zoom != null:
		return
	if is_local_mode():
		if camera.zoom.x < LOCAL_TO_MAP_ZOOM:
			_zoom_out_to_world_map()
	elif camera.zoom.x * _map_to_local_scale() > MAP_TO_LOCAL_ZOOM:
		_zoom_in_to_local()


# ワールドマップの長さをローカル画面の長さに直す倍率
func _map_to_local_scale() -> float:
	return world_map_view.get_tile_spacing() / world.get_chunk_spacing()


# 見え方を保ったままワールドマップへ移る
func _zoom_out_to_world_map() -> void:
	var local_position = camera.position
	var local_zoom = camera.zoom.x
	_enter_world_map_mode()
	var scale = _map_to_local_scale()
	var tile = world_map_view.get_tile_position(world.get_active_hex())
	camera.position = world_map_view.to_global(tile + local_position * scale)
	camera.zoom = Vector2.ONE * (local_zoom / scale)


# キャラクターのいる chunk のローカル画面へ、倍率を保ったまま入る。カメラはキャラクターに合わせる
func _zoom_in_to_local() -> void:
	var map_zoom = camera.zoom.x
	var scale = _map_to_local_scale()
	_handle_world_map_chunk_selected(world.player.chunk_hex)
	camera.position = world.get_player_position()
	camera.zoom = Vector2.ONE * (map_zoom * scale)


func is_local_mode() -> bool:
	return world.visible


func _on_hud_slot_selected(scene: PackedScene):
	piece_placer.select_piece(scene)


func _unhandled_input(event):
	# 戦闘中の操作は戦闘画面が受け取る
	if battle_overlay.is_open():
		return
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
		elif event.keycode == CROSS_KEY and is_local_mode():
			try_cross()


func _toggle_mode():
	if is_local_mode():
		_enter_world_map_mode()
	else:
		_enter_local_mode()


func _activate_chunk(chunk_hex: Vector2i) -> void:
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
	_refresh_world_map()
	_refresh_camera_keyboard()
	_local_camera_position = camera.position
	if world.get_active_hex() != null:
		var tile_pos = world_map_view.get_tile_position(world.get_active_hex())
		camera.position = world_map_view.to_global(tile_pos)
	_refresh_debug_overlay()


# ワールドマップのタイル（霧・今いる chunk の印）と接続の矢印を、いまの状態で作り直す
func _refresh_world_map() -> void:
	world_map_view.setup(world)
	if world.get_active_hex() != null:
		world_map_view.set_active_chunk(world.get_active_hex())
	world_map_view.refresh_connections(world.get_connected_chunk_pairs())


func _enter_local_mode():
	world.visible = true
	hud.visible = true
	piece_placer.visible = true
	world_map_view.visible = false
	camera.position = _local_camera_position
	_refresh_camera_keyboard()
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
			select_world_map_chunk(hex)


# ワールドマップで所有している chunk を選ぶと、キャラクターのいる chunk の画面に戻る。
# chunk の間はキャラクターが歩いて渡るので、地図から別の chunk へ飛んだり戦いを始めたりはしない
func select_world_map_chunk(hex: Vector2i) -> void:
	if world.territory.is_owned(hex):
		_handle_world_map_chunk_selected(world.player.chunk_hex)


# chunk を解放するための戦闘を始める。その chunk の画面に入り、chunk のマスの上でそのまま戦う。
# 主人公は start_hex のマス（キャラクターが入ってきたマス）から始まる。戦闘中も工場は動き続ける
func start_battle(chunk_hex: Vector2i, start_hex = null) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_battle_chunk_hex = chunk_hex
	_pre_battle = {
		"active_hex": world.get_active_hex(),
		"camera_zoom": camera.zoom,
		"camera_min_zoom": camera.min_zoom,
	}
	_handle_world_map_chunk_selected(chunk_hex)
	_set_build_ui_visible(false)
	var view = battle_camera_view(get_viewport().get_visible_rect().size)
	camera.position = view["position"]
	camera.zoom = Vector2.ONE * view["zoom"]
	camera.min_zoom = minf(BATTLE_MIN_ZOOM, view["zoom"])
	_battle_turn = ChunkBattle.create(chunk_hex, world.get_active_chunk(), rng, start_hex)
	battle_overlay.open(_battle_turn, world)
	world.player_shown = false
	_refresh_camera_keyboard()


# 大きさ screen_size の画面で、今いる chunk 全体がスキルのボタンに隠れずに収まるカメラ
# {position, zoom}。chunk の中心は、ボタンを除いた残りの領域の真ん中に来る
func battle_camera_view(screen_size: Vector2) -> Dictionary:
	var chunk = world.get_active_chunk()
	var cell = HexTile.visual_circumradius()
	var half_cell = Vector2(cell * sqrt(3.0) / 2.0, cell)
	var bounds := Rect2(chunk.hex_to_pixel(Vector2i(0, 0)), Vector2.ZERO)
	for hex in chunk.get_all_hexes():
		var center = chunk.hex_to_pixel(hex)
		bounds = bounds.merge(Rect2(center - half_cell, half_cell * 2.0))
	var area = (
		screen_size - Vector2(BATTLE_MARGIN * 2.0, BATTLE_MARGIN * 2.0 + BATTLE_BOTTOM_RESERVED)
	)
	# ボタンより小さい画面でも、倍率が 0 やマイナスにならないようにする
	area = area.max(Vector2.ONE)
	var zoom = minf(area.x / bounds.size.x, area.y / bounds.size.y)
	# ボタンを除いた領域の真ん中は、画面の真ん中よりボタンの高さの半分だけ上にある
	var shift = Vector2(0, BATTLE_BOTTOM_RESERVED / 2.0 / zoom)
	return {"position": bounds.get_center() + shift, "zoom": zoom}


# 勝ったらその chunk を所有し、キャラクターは主人公が戦い終えたマスに立って、そのまま建築に移る。
# 負けたり撤退したりしたら、キャラクターは渡る前のマスに残り、戦闘前の建築の画面に戻る
func _on_battle_closed(won: bool) -> void:
	camera.min_zoom = _pre_battle["camera_min_zoom"]
	if won:
		world.territory.claim(_battle_chunk_hex)
		world.place_player(_battle_chunk_hex, _battle_turn.battle.player.position)
		_camera_target_zoom = _pre_battle["camera_zoom"].x
	else:
		_activate_chunk(_pre_battle["active_hex"])
		world_map_view.set_active_chunk(_pre_battle["active_hex"])
		# 元の chunk が原点に戻り、戦った chunk は隣へずれる。見え方を保つようにカメラも同じだけずらす
		camera.position += world.get_chunk(_battle_chunk_hex).position
		_camera_target_zoom = _pre_battle["camera_zoom"].x
	# 戦闘の視点から、一瞬で飛ばずにキャラクターへ戻る
	_camera_following = true
	_set_build_ui_visible(true)
	world.player_shown = true
	_battle_chunk_hex = null
	_battle_turn = null
	_pre_battle = {}
	_refresh_camera_keyboard()


# 建築のための表示（ツールバーなどの HUD と、設置するピースのプレビュー）を出す・隠す
func _set_build_ui_visible(shown: bool) -> void:
	if not shown:
		hud.deselect()
		hud.show_hovered_piece(null)
	hud.visible = shown
	piece_placer.visible = shown


# chunk のローカル画面へ入る（所有しているかは呼び出し側で確かめる）
func _handle_world_map_chunk_selected(hex: Vector2i) -> void:
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
