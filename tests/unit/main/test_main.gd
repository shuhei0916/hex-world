extends GutTest

const MainScene = preload("res://scenes/main/main.tscn")

var main: Main


func before_each():
	main = MainScene.instantiate()
	add_child_autofree(main)


func after_each():
	await get_tree().process_frame


func test_HUDのスロット選択でPiecePlacerが更新される():
	var btn = main.hud.toolbar.get_child(0) as Button
	btn.button_pressed = true
	main.hud.on_slot_pressed(0)
	assert_not_null(main.piece_placer.selected_scene)


func test_ピースを設置すると設置音が鳴る():
	var smelter_scene = main.hud.get_scene_for_slot(3)
	main.world.get_active_chunk().place_piece(smelter_scene, Hex.new(0, 0))
	assert_true(main.get_node("SfxPlayer/PlaceBuilding").playing)


func test_コンベアをドラッグパスに追加すると設置音が鳴る():
	var conveyor_scene = main.hud.get_scene_for_slot(0)
	main.piece_placer.select_piece(conveyor_scene)
	main.piece_placer.start_drag()
	main.piece_placer.place_piece_at_hex(Hex.new(1, 0))
	assert_true(main.get_node("SfxPlayer/PlaceBelt").playing)


func test_起動時の初期配置では音が鳴らない():
	assert_false(main.get_node("SfxPlayer/PlaceBuilding").playing)


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


func test_ワールドマップでHex_0_0タイルをクリックするとローカルモードに戻る():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Hex.new(0, 0))
	assert_true(main.is_local_mode())


func test_クリックしたチャンクがアクティブになる():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Hex.new(1, 0))
	assert_eq(main.world.get_active_chunk(), main.world.get_chunk(Hex.new(1, 0)))


func test_ワールドマップ再入時に現在アクティブなチャンクが強調される():
	main._handle_key_input(_make_space_event())
	main._handle_world_map_chunk_selected(Hex.new(1, 0))
	main._handle_key_input(_make_space_event())
	assert_true(main.world_map_view.get_tile_active(Hex.new(1, 0)))
