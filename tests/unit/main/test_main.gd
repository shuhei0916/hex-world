# gdlint:disable=max-public-methods
extends GutTest

const MainScene = preload("res://scenes/main/main.tscn")
const SAVE_PATH := "user://test_main_save.json"
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")

var main: Main


func before_each():
	# 本物のセーブデータを読み書きしないよう、テスト用のファイルに差し替える
	SaveGame.path = SAVE_PATH
	SaveGame.delete()
	HubGoals.reset()
	main = MainScene.instantiate()
	add_child_autofree(main)


func after_each():
	await get_tree().process_frame
	SaveGame.delete()
	SaveGame.path = SaveGame.DEFAULT_PATH
	HubGoals.reset()


func _start_another_main() -> Main:
	var other = MainScene.instantiate()
	add_child_autofree(other)
	return other


func test_HUDのスロット選択でPiecePlacerが更新される():
	var btn = main.hud.toolbar.get_child(0) as Button
	btn.button_pressed = true
	main.hud.on_slot_pressed(0)
	assert_not_null(main.piece_placer.selected_scene)


func test_ピースを設置すると設置音が鳴る():
	var smelter_scene = main.hud.get_scene_for_slot(3)
	main.world.get_active_chunk().place_piece(smelter_scene, Vector2i(0, 0))
	assert_true(main.get_node("SfxPlayer/PlaceBuilding").playing)


func test_コンベアをドラッグパスに追加すると設置音が鳴る():
	var conveyor_scene = main.hud.get_scene_for_slot(0)
	main.piece_placer.select_piece(conveyor_scene)
	main.piece_placer.start_drag()
	main.piece_placer.place_piece_at_hex(Vector2i(1, 0))
	assert_true(main.get_node("SfxPlayer/PlaceBelt").playing)


func test_起動時の初期配置では音が鳴らない():
	assert_false(main.get_node("SfxPlayer/PlaceBuilding").playing)


func test_起動時にplanetが設定され原点chunkと周りに見える隣のchunkが生成される():
	assert_eq(main.world.get_planet().radius, Main.PLANET_RADIUS)
	assert_eq(main.world.get_chunk_hexes().size(), 7)
	assert_true(main.world.get_active_hex() == Vector2i(0, 0))


func test_原点chunkにはハブと鉄鉱石の鉱床がある():
	var chunk = main.world.get_active_chunk()
	assert_eq(chunk.get_piece_at_hex(Vector2i(0, 0)).piece_type, PieceData.Type.HUB)
	var ore_count = 0
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) == "iron_ore":
			ore_count += 1
	assert_eq(ore_count, World.DEPOSIT_SIZE)


func _make_right_button_event(pressed: bool) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	return event


func test_ピース未選択で右ボタンを押すと削除ドラッグが開始される():
	main._handle_mouse_click(_make_right_button_event(true))
	assert_true(main.piece_placer.is_delete_dragging)


func test_右ボタンを離すと削除ドラッグが終了する():
	main._handle_mouse_click(_make_right_button_event(true))
	main._handle_mouse_click(_make_right_button_event(false))
	assert_false(main.piece_placer.is_delete_dragging)


func test_ツールバー選択中の右クリックでは削除ドラッグが開始されない():
	var btn = main.hud.toolbar.get_child(0) as Button
	btn.button_pressed = true
	main._handle_mouse_click(_make_right_button_event(true))
	assert_false(main.piece_placer.is_delete_dragging)


func _make_space_event() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	return event


func _make_f3_event() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_F3
	event.pressed = true
	return event


func test_F3キーでクリエイティブモードがトグルされる():
	main._handle_key_input(_make_f3_event())
	assert_true(HubGoals.creative_mode)
	HubGoals.creative_mode = false


func test_初期モードはローカルマップ():
	assert_true(main.is_local_mode())


func test_Spaceキーでワールドマップモードに切り替わる():
	main._handle_key_input(_make_space_event())
	assert_false(main.is_local_mode())


func test_ワールドマップ時はWorldが非表示():
	main._handle_key_input(_make_space_event())
	assert_false(main.world.visible)


func test_ワールドマップ時はWorldMapViewが表示():
	main._handle_key_input(_make_space_event())
	assert_true(main.world_map_view.visible)


func test_再度SpaceでローカルモードにもどるWorldが表示される():
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_space_event())
	assert_true(main.world.visible)


func _make_left_click_event(pos: Vector2) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	return event


func test_ワールドマップ時はHUDが非表示():
	main._handle_key_input(_make_space_event())
	assert_false(main.hud.visible)


func test_ローカルモードに戻るとHUDが再表示される():
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_space_event())
	assert_true(main.hud.visible)


func test_ワールドマップ時はPiecePlacerが非表示():
	main._handle_key_input(_make_space_event())
	assert_false(main.piece_placer.visible)


func test_ローカルモードに戻るとPiecePlacerが再表示される():
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_space_event())
	assert_true(main.piece_placer.visible)


func _make_f2_event() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_F2
	event.pressed = true
	return event


func test_F2表示中にワールドマップへ切り替えるとチャンク座標ラベルになる():
	main._handle_key_input(_make_f2_event())
	main._handle_key_input(_make_space_event())
	assert_eq(main.debug_overlay.get_label_count(), main.world.get_map_hexes().size())


func test_ワールドマップ表示中にF2を押すとチャンク座標ラベルが表示される():
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_f2_event())
	assert_eq(main.debug_overlay.get_label_count(), main.world.get_map_hexes().size())


func test_F2表示中にローカルへ戻るとヘックス座標ラベルに戻る():
	main._handle_key_input(_make_f2_event())
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_space_event())
	var expected = main.world.get_active_chunk().get_grid_hex_count()
	assert_eq(main.debug_overlay.get_label_count(), expected)


func test_チャンク切替でHUDの座標ラベルが更新される():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Vector2i(1, 0))
	assert_eq(main.hud.get_node("ChunkCoordLabel").text, "Chunk: 1, 0")


func test_ワールドマップ表示時に接続済みチャンクペアの矢印が表示される():
	var bridge_scene = main.hud.get_scene_for_slot(6)
	main.world.get_active_chunk().place_piece(bridge_scene, Vector2i(4, 1))
	var chunk_b = main.world.create_chunk(Vector2i(1, 0))
	chunk_b.place_piece(CONVEYOR, Vector2i(-1, -4))
	main._handle_key_input(_make_space_event())
	assert_eq(main.world_map_view.get_connection_arrow_count(), 1)


func test_ワールドマップでHex_0_0タイルをクリックするとローカルモードに戻る():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Vector2i(0, 0))
	assert_true(main.is_local_mode())


func test_クリックしたチャンクがアクティブになる():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Vector2i(1, 0))
	assert_eq(main.world.get_active_chunk(), main.world.get_chunk(Vector2i(1, 0)))


func test_ワールドマップ再入時に現在アクティブなチャンクが強調される():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Vector2i(1, 0))
	main._handle_key_input(_make_space_event())
	assert_true(main.world_map_view.get_tile_active(Vector2i(1, 0)))


func _make_mouse_motion_event(pos: Vector2) -> InputEventMouseMotion:
	var event = InputEventMouseMotion.new()
	event.position = pos
	return event


func test_ワールドマップモードでマウス移動するとホバー先タイルが更新される():
	main._handle_key_input(_make_space_event())
	var pos = main.world_map_view.get_tile_position(Vector2i(1, 0))
	main._handle_mouse_motion(_make_mouse_motion_event(pos))
	assert_true(main.world_map_view.get_tile_hovered(Vector2i(1, 0)))


func test_ワールドマップにはplanetの全chunkが表示される():
	main._handle_key_input(_make_space_event())
	var expected = main.world.get_planet().get_chunk_hexes().size()
	assert_eq(main.world_map_view.get_tile_count(), expected)


func test_未生成のchunkを選ぶとそのchunkに入れる():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Vector2i(-2, 1))
	assert_true(main.is_local_mode())
	assert_not_null(main.world.get_chunk(Vector2i(-2, 1)))
	assert_eq(main.piece_placer.chunk, main.world.get_chunk(Vector2i(-2, 1)))


func test_ワールドマップに入るとカメラがアクティブchunkのタイルへ移る():
	main._handle_world_map_chunk_selected(Vector2i(1, 0))
	main._handle_key_input(_make_space_event())
	var expected = main.world_map_view.to_global(
		main.world_map_view.get_tile_position(Vector2i(1, 0))
	)
	assert_eq(main.camera.position, expected)


func test_ローカルに戻るとワールドマップに入る前のカメラ位置に戻る():
	main.camera.position = Vector2(123, 45)
	main._handle_key_input(_make_space_event())
	main._handle_key_input(_make_space_event())
	assert_eq(main.camera.position, Vector2(123, 45))


func test_ポーズメニューの終了要求でゲームを終了する処理につながっている():
	assert_true(main.pause_menu.quit_requested.is_connected(main._on_pause_menu_quit_requested))


func test_ポーズメニューはHUDより手前に表示される():
	assert_gt(main.pause_menu.layer, main.hud.layer)


func test_セーブデータが無ければ新しいゲームとして始まる():
	assert_eq(main.world.get_chunk_hexes().size(), 7, "原点と周りの6つ")
	assert_eq(main.world.get_active_chunk().get_piece_count(), 1, "ハブだけがある")


func test_セーブすると次の起動で設置したピースが復元される():
	main.world.get_active_chunk().place_piece(CONVEYOR, Vector2i(2, 1), 4)
	main.save_game()
	var piece = _start_another_main().world.get_active_chunk().get_piece_at_hex(Vector2i(2, 1))
	assert_not_null(piece)
	assert_eq(piece.rotation_state, 4)


func test_ロードしてもハブは1つだけ():
	main.save_game()
	var chunk = _start_another_main().world.get_chunk(Vector2i(0, 0))
	var hubs = chunk.get_all_pieces().filter(func(p): return p.piece_type == PieceData.Type.HUB)
	assert_eq(hubs.size(), 1)


func test_ロードすると最後にいたchunkから再開しピース設置先もそのchunkになる():
	main._handle_world_map_chunk_selected(Vector2i(1, 0))
	main.save_game()
	var other = _start_another_main()
	assert_true(other.world.get_active_hex() == Vector2i(1, 0))
	assert_eq(other.piece_placer.chunk, other.world.get_active_chunk())


func test_ロードすると解放済みのピースがツールバーで使える():
	HubGoals.advance_level()
	main.save_game()
	HubGoals.reset()
	var other = _start_another_main()
	assert_eq(HubGoals.level, 2)
	assert_true(HubGoals.is_reward_unlocked("unlock_smelter"))
	assert_false(other.hud.slot_buttons[2].disabled, "Smelter のスロット")


func test_ポーズメニューのセーブ要求でセーブされ結果が表示される():
	main.pause_menu.save_requested.emit()
	assert_true(SaveGame.exists())
	assert_eq(main.pause_menu.status_label.text, "セーブしました")


func test_壊れたセーブデータなら新しいゲームとして始まる():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("こわれたデータ")
	file.close()
	var other = _start_another_main()
	assert_eq(other.world.get_active_chunk().get_piece_count(), 1, "ハブだけがある")


func test_最初からやり直すとセーブデータと進行度が消える():
	HubGoals.advance_level()
	main.save_game()
	main.discard_progress()
	assert_false(SaveGame.exists())
	assert_eq(HubGoals.level, 1)


func test_設置済みピースの上にマウスを置くとそのピースの情報が表示される():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	assert_true(main.hud.info_panel.visible)
	assert_eq(main.hud.info_panel.name_label.text, "Conveyor")


func test_隣のchunkの施設の上にマウスを置いてもその情報が表示される():
	var neighbor = main.world.get_chunk(Vector2i(1, 0))
	neighbor.place_piece(CONVEYOR, Vector2i(-2, 1))
	main._hover_local(neighbor.position + neighbor.hex_to_pixel(Vector2i(-2, 1)))
	assert_true(main.hud.info_panel.visible)
	assert_eq(main.hud.info_panel.name_label.text, "Conveyor")


func test_何も無いマスにマウスを移すとピースの情報が消える():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._hover_local(chunk.hex_to_pixel(Vector2i(3, -2)))
	assert_false(main.hud.info_panel.visible)


func test_ワールドマップに切り替えるとピースの情報が消える():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._toggle_mode()
	main._toggle_mode()
	assert_false(main.hud.info_panel.visible)


func _make_key_event(keycode: Key) -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func test_Eキーで研究パネルが開閉する():
	main._handle_key_input(_make_key_event(KEY_E))
	assert_true(main.hud.research_panel.visible)
	main._handle_key_input(_make_key_event(KEY_E))
	assert_false(main.hud.research_panel.visible)


func test_ワールドマップではEキーで研究パネルが開かない():
	main._toggle_mode()
	main._handle_key_input(_make_key_event(KEY_E))
	assert_false(main.hud.research_panel.visible)


func test_研究でコンベアを速くすると情報パネルのスピードに反映される():
	HubGoals.researched = {"belt_speed_1": true}
	main.hud.slot_buttons[0].button_pressed = true
	main.hud.on_slot_pressed(0)
	assert_eq(main.hud.info_panel.rate_label.text, "スピード: 180/分")


func _left_click(pressed: bool) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func test_何も選んでいない状態で搬出チェストをクリックするとアイテム選択パネルが開く():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CHEST_OUT, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._handle_local_click(_left_click(true))
	assert_true(main.hud.item_picker.visible)


func test_設置するピースを選んでいるときは搬出チェストをクリックしてもパネルが開かない():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CHEST_OUT, Vector2i(2, 1))
	main.hud.slot_buttons[0].button_pressed = true
	main.hud.on_slot_pressed(0)
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._handle_local_click(_left_click(true))
	assert_false(main.hud.item_picker.visible)


func test_コンベアをクリックしてもアイテム選択パネルは開かない():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._handle_local_click(_left_click(true))
	assert_false(main.hud.item_picker.visible)


func _right_click(pressed: bool) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	return event


func test_研究画面を開いている間はホイールでマップを拡縮できない():
	main._handle_key_input(_make_key_event(KEY_E))
	assert_false(main.camera.zoom_enabled)
	main._handle_key_input(_make_key_event(KEY_E))
	assert_true(main.camera.zoom_enabled)


func test_アイテム選択パネルを開いている間もホイールでマップを拡縮できない():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CHEST_OUT, Vector2i(2, 1))
	main.hud.open_item_picker(chunk.get_piece_at_hex(Vector2i(2, 1)))
	assert_false(main.camera.zoom_enabled)
	main.hud.item_picker.get_button("coal").pressed.emit()
	assert_true(main.camera.zoom_enabled)


func test_研究画面を開いている間に盤面を左クリックしても設置されず研究画面が閉じる():
	var chunk = main.world.get_active_chunk()
	main._handle_key_input(_make_key_event(KEY_E))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._handle_local_click(_left_click(true))
	assert_false(main.hud.research_panel.visible)
	assert_null(chunk.get_piece_at_hex(Vector2i(2, 1)))
	assert_false(main.piece_placer.is_dragging)


func test_研究画面を開いている間に盤面を右クリックしてもピースは撤去されない():
	var chunk = main.world.get_active_chunk()
	chunk.place_piece(CONVEYOR, Vector2i(2, 1))
	main._hover_local(chunk.hex_to_pixel(Vector2i(2, 1)))
	main._handle_key_input(_make_key_event(KEY_E))
	main._handle_local_click(_right_click(true))
	assert_not_null(chunk.get_piece_at_hex(Vector2i(2, 1)))
	assert_false(main.hud.research_panel.visible)


func test_研究画面を開くと設置しようとしていたピースの選択が解除される():
	main.hud.slot_buttons[0].button_pressed = true
	main.hud.on_slot_pressed(0)
	main.piece_placer.select_piece(main.hud.get_scene_for_slot(0))
	main._handle_key_input(_make_key_event(KEY_E))
	assert_null(main.piece_placer.selected_scene)


func test_在庫不足で置けないとカーソル付近にメッセージが出る():
	var chunk = main.world.get_active_chunk()
	main.hud.slot_buttons[2].button_pressed = true
	main.piece_placer.select_piece(main.hud.get_scene_for_slot(2))
	main._hover_local(chunk.hex_to_pixel(Vector2i(3, -1)))
	main.piece_placer.place_current_piece()
	assert_true(main.hud.cursor_message.visible)
	assert_eq(main.hud.cursor_message.text, "在庫不足: Iron Ore 0/5")


# ---- 所有と戦闘 --------------------------------------------------------------


# いまの戦闘の敵をすべて取り除いて勝たせる
func _win_battle() -> void:
	var scene = main.battle_overlay.battle_scene
	for enemy in scene.battle.enemies():
		scene.battle.field.remove_unit(enemy)
	scene.refresh()


func test_新しいゲームでは原点のchunkだけを所有している():
	assert_true(main.world.territory.is_owned(Vector2i(0, 0)))
	assert_eq(main.world.territory.get_owned_hexes().size(), 1)


func test_ワールドマップで所有しているchunkを選ぶと_キャラクターのいるchunkに戻る():
	# chunk の間はキャラクターが歩いて移るので、地図から別の chunk へは飛ばない
	main.world.territory.claim(Vector2i(1, 0))
	main._handle_key_input(_make_space_event())
	main.select_world_map_chunk(Vector2i(1, 0))
	assert_true(main.is_local_mode())
	assert_true(main.world.get_active_hex() == Vector2i(0, 0))


# ワールドマップで東隣の chunk を選んで戦闘を始める
func _start_battle_on_east() -> Vector2i:
	var hex = Vector2i(1, 0)
	main._handle_key_input(_make_space_event())
	main.select_world_map_chunk(hex)
	return hex


func test_ワールドマップで所有しているchunkの隣を選ぶと_そのchunkの上で戦闘が始まる():
	var hex = _start_battle_on_east()
	assert_true(main.battle_overlay.is_open())
	assert_true(main.is_local_mode())
	assert_true(main.world.get_active_hex() == hex)
	assert_eq(main.battle_overlay.battle_scene.get_parent(), main.world)


func test_戦闘の戦場はそのchunkのマスで_鉱床は壁になる():
	var hex = _start_battle_on_east()
	var chunk = main.world.get_chunk(hex)
	var field = main.battle_overlay.battle_scene.battle.field
	assert_eq(field.cells().size(), chunk.get_grid_hex_count())
	var walls = ChunkBattle.walls_of(chunk)
	assert_gt(walls.size(), 0)
	for wall in walls:
		assert_eq(field.terrain_at(wall), Battlefield.Terrain.WALL)


func test_戦闘中は建築のHUDとピースの設置を隠す():
	_start_battle_on_east()
	assert_false(main.hud.visible)
	assert_false(main.piece_placer.visible)


func test_戦闘中は盤面全体が見える位置と倍率にカメラを合わせる():
	_start_battle_on_east()
	assert_eq(main.camera.position, Main.BATTLE_CAMERA_POSITION)
	assert_eq(main.camera.zoom, Vector2.ONE * Main.BATTLE_CAMERA_ZOOM)


func test_ワールドマップで霧のchunkを選んでも何も起きない():
	main._handle_key_input(_make_space_event())
	main.select_world_map_chunk(Vector2i(2, 0))
	assert_false(main.battle_overlay.is_open())
	assert_false(main.is_local_mode())


func test_戦闘に勝って結果を閉じるとそのchunkを所有し_そのまま建築できる():
	var hex = _start_battle_on_east()
	_win_battle()
	main.battle_overlay.confirm_result()
	assert_true(main.world.territory.is_owned(hex))
	assert_true(main.is_local_mode())
	assert_true(main.world.get_active_hex() == hex)
	assert_true(main.hud.visible)
	assert_true(main.piece_placer.visible)
	assert_eq(main.piece_placer.chunk, main.world.get_chunk(hex))


func test_戦闘に勝つとキャラクターは戦い終えたマスに立つ():
	var hex = _start_battle_on_east()
	var end_hex = main.battle_overlay.battle_scene.battle.player.position
	_win_battle()
	main.battle_overlay.confirm_result()
	assert_eq(main.world.player.chunk_hex, hex)
	assert_eq(main.world.player.hex, end_hex)


func test_戦闘から撤退するとキャラクターは元の場所に残る():
	var before_hex = main.world.player.hex
	_start_battle_on_east()
	main.battle_overlay.retreat()
	assert_eq(main.world.player.chunk_hex, Vector2i(0, 0))
	assert_eq(main.world.player.hex, before_hex)


func test_戦闘に勝ったあと地図を開くと霧が晴れている():
	var hex = _start_battle_on_east()
	_win_battle()
	main.battle_overlay.confirm_result()
	main._handle_key_input(_make_space_event())
	main.world_map_view.set_hovered_chunk(hex)
	assert_ne(main.world_map_view.get_hover_info_text(), "")
	assert_eq(main.world_map_view.get_hover_info_text().find("戦って解放"), -1)
	assert_true(main.world_map_view.get_tile_active(hex), "今いる chunk の印が付く")


func test_戦闘から撤退するとそのchunkは所有せず_元のchunkの地図に戻る():
	var hex = _start_battle_on_east()
	main.battle_overlay.retreat()
	assert_false(main.world.territory.is_owned(hex))
	assert_false(main.battle_overlay.is_open())
	assert_false(main.is_local_mode())
	assert_true(main.world.get_active_hex() == Vector2i(0, 0))
	assert_true(main.world_map_view.get_tile_active(Vector2i(0, 0)))


func test_戦闘から撤退するとカメラは戦闘前の地図の位置と倍率に戻る():
	main._handle_key_input(_make_space_event())
	main.camera.zoom = Vector2.ONE * 0.5
	main.camera.position += Vector2(30, 10)
	var position_before = main.camera.position
	main.select_world_map_chunk(Vector2i(1, 0))
	main.battle_overlay.retreat()
	assert_eq(main.camera.position, position_before)
	assert_eq(main.camera.zoom, Vector2.ONE * 0.5)


func test_戦闘から撤退して所有するchunkに入ると_戦闘前に見ていた位置が映る():
	main.camera.position = Vector2(120, -80)
	_start_battle_on_east()
	main.battle_overlay.retreat()
	main._handle_key_input(_make_space_event())
	assert_eq(main.camera.position, Vector2(120, -80))


func test_戦闘中はスペースを押しても地図に切り替わらない():
	_start_battle_on_east()
	main._unhandled_input(_make_space_event())
	assert_true(main.is_local_mode())
	assert_true(main.battle_overlay.is_open())


func _wheel_event(button: MouseButton) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_戦闘中もカメラを動かせる():
	_start_battle_on_east()
	assert_true(main.camera.is_processing_unhandled_input(), "ホイールと中ボタンドラッグ")
	assert_true(main.camera.is_processing(), "キーでの移動")
	main.camera._unhandled_input(_wheel_event(MOUSE_BUTTON_WHEEL_UP))
	assert_gt(main.camera.zoom.x, Main.BATTLE_CAMERA_ZOOM)


func test_戦闘中にカメラを動かしても_戦っているchunkのままで戦闘は続く():
	var hex = _start_battle_on_east()
	# 所有している西隣（原点）の chunk の中心までパンする
	main.camera.position = main.world.get_chunk(Vector2i(0, 0)).position
	main.update_navigation()
	assert_true(main.world.get_active_hex() == hex)
	assert_true(main.battle_overlay.is_open())


func test_戦闘中はいくら引いても地図には切り替わらない():
	_start_battle_on_east()
	for i in range(30):
		main.camera._unhandled_input(_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))
	main.update_navigation()
	assert_almost_eq(main.camera.zoom.x, Main.BATTLE_MIN_ZOOM, 0.0001)
	assert_gt(Main.BATTLE_MIN_ZOOM, Main.LOCAL_TO_MAP_ZOOM)
	assert_true(main.is_local_mode())


func test_戦闘中に引けるだけ引いて勝っても_そのまま建築の画面に残る():
	var hex = _start_battle_on_east()
	for i in range(30):
		main.camera._unhandled_input(_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))
	_win_battle()
	main.battle_overlay.confirm_result()
	main.update_navigation()
	assert_true(main.is_local_mode())
	assert_true(main.world.get_active_hex() == hex)


func test_戦闘が終わると_地図に切り替わるところまで引けるようになる():
	var min_zoom_before = main.camera.min_zoom
	_start_battle_on_east()
	main.battle_overlay.retreat()
	assert_eq(main.camera.min_zoom, min_zoom_before)


func test_戦闘中にセーブしても_今いるchunkは戦闘前のchunkとして保存する():
	_start_battle_on_east()
	main.save_game()
	var other = _start_another_main()
	assert_true(other.world.get_active_hex() == Vector2i(0, 0))
	assert_false(other.world.territory.is_owned(Vector2i(1, 0)))


class TestPlayerSpawn:
	extends GutTest

	## 新しいゲームでも、キャラクターの記録が無い旧セーブでも、今いる chunk のハブの隣に立つ。

	func before_each():
		SaveGame.path = SAVE_PATH
		SaveGame.delete()
		HubGoals.reset()

	func after_each():
		await get_tree().process_frame
		SaveGame.delete()
		SaveGame.path = SaveGame.DEFAULT_PATH
		HubGoals.reset()

	func _start() -> Main:
		var main = MainScene.instantiate()
		add_child_autofree(main)
		return main

	func test_新しいゲームではハブの隣に立つ():
		var main = _start()
		assert_eq(main.world.player.chunk_hex, Vector2i(0, 0))
		assert_eq(Hex.distance(main.world.player.hex, Vector2i(0, 0)), 1)

	func test_キャラクターの記録が無いセーブを読むと今いるchunkのハブの隣に立つ():
		var first = _start()
		var data = SaveGame.capture(first.world, HubGoals)
		data.erase("player")
		SaveGame.write(SAVE_PATH, data)
		var main = _start()
		assert_eq(main.world.player.chunk_hex, main.world.get_active_hex())
		assert_eq(Hex.distance(main.world.player.hex, Vector2i(0, 0)), 1)
