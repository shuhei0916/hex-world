extends GutTest

const MainScene = preload("res://scenes/main/main.tscn")

var main: Main


func before_each():
	main = MainScene.instantiate()
	add_child_autofree(main)


func after_each():
	await get_tree().process_frame


func test_MainはGridManagerを持つ():
	assert_not_null(main.grid_manager)
	assert_true(main.grid_manager is GridManager)


func test_グリッド更新シグナルでGridManagerに登録される():
	var gm = main.grid_manager
	if gm == null:
		fail_test("GridManager not found")
		return

	gm.clear_grid()

	gm.create_hex_grid(2)
	assert_true(gm.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")


func test_MainはHUDを持つ():
	var hud = main.hud
	assert_not_null(hud, "HUD node should be linked in Main")

	if hud:
		assert_true(hud is HUD)


func test_ピース選択中に右クリックで選択解除される():
	# まずピースを選択
	main.hud.select_slot(0)
	assert_eq(main.hud.get_active_index(), 0)

	# 右クリックイベント
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	main._unhandled_input(event)

	assert_eq(main.hud.get_active_index(), -1, "右クリックで選択が解除されるべき")
	assert_null(main.piece_placer.selected_piece_data, "PiecePlacerの選択も解除されるべき")


func test_未選択時に右クリックでピース削除される():
	var hex = Hex.new(0, 0)
	main.hud.select_slot(0)  # BAR
	main.place_selected_piece(hex)
	assert_true(main.grid_manager.is_occupied(hex), "ピースが配置されているべき")

	# 選択解除
	main.hud.select_slot(-1)

	# マウス位置を(0,0)に更新
	main.piece_placer.update_hover(main.grid_manager.hex_to_pixel(hex))

	# 右クリックイベント
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	main._unhandled_input(event)

	assert_false(main.grid_manager.is_occupied(hex), "素手状態の右クリックでピースが削除されるべき")


func test_ピース選択中に右クリックで削除は行われない():
	var hex = Hex.new(0, 0)
	main.hud.select_slot(1)  # WORM
	main.place_selected_piece(hex)

	# 別のピースを選択中
	main.hud.select_slot(0)  # BAR
	assert_eq(main.hud.get_active_index(), 0)

	# マウス位置を(0,0)に更新
	main.piece_placer.update_hover(main.grid_manager.hex_to_pixel(hex))

	# 右クリックイベント
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	main._unhandled_input(event)

	assert_eq(main.hud.get_active_index(), -1, "まず選択が解除される")
	assert_true(main.grid_manager.is_occupied(hex), "選択解除が優先され、削除は行われないべき")


func test_Tキー入力で詳細モードが切り替わる():
	assert_false(main.grid_manager.is_detail_mode_enabled, "初期状態はfalse")

	var event = InputEventKey.new()
	event.keycode = KEY_T
	event.pressed = true

	main._unhandled_input(event)
	assert_true(main.grid_manager.is_detail_mode_enabled, "Tキーでtrueになるべき")

	main._unhandled_input(event)
	assert_false(main.grid_manager.is_detail_mode_enabled, "再度Tキーでfalseになるべき")
