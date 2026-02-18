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


func test_Tキー入力で詳細モードが切り替わる():
	assert_false(main.grid_manager.is_detail_mode_enabled, "初期状態はfalse")

	var event = InputEventKey.new()
	event.keycode = KEY_T
	event.pressed = true

	main._unhandled_input(event)
	assert_true(main.grid_manager.is_detail_mode_enabled, "Tキーでtrueになるべき")

	main._unhandled_input(event)
	assert_false(main.grid_manager.is_detail_mode_enabled, "再度Tキーでfalseになるべき")
