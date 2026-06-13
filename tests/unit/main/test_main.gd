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
	main.chunk.place_piece(smelter_scene, Hex.new(0, 0))
	assert_true(main.get_node("SfxPlayer/PlaceBuilding").playing)


func test_コンベアをドラッグパスに追加すると設置音が鳴る():
	var conveyor_scene = main.hud.get_scene_for_slot(0)
	main.piece_placer.select_piece(conveyor_scene)
	main.piece_placer.start_drag()
	main.piece_placer.place_piece_at_hex(Hex.new(0, 0))
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
