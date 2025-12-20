extends GutTest
class_name TestMain

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

func test_MainはPaletteを持つ():
	assert_not_null(main.palette)
	assert_true(main.palette is Palette)

func test_MainはHUDを持ちPaletteが注入されている():
	var hud = main.hud
	assert_not_null(hud, "HUD node should be linked in Main (Check if HUD is added to Main scene)")
	
	if hud:
		assert_true(hud is HUD)
		var ui = hud.palette_ui
		assert_not_null(ui, "PaletteUI should exist in HUD")
		if ui:
			assert_eq(ui.palette, main.palette, "PaletteUI should have the same Palette instance")

func test_数字キー入力でPaletteの選択が変更される():
	assert_eq(main.palette.get_active_index(), -1)
	
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	main._unhandled_input(event)
	
	assert_eq(main.palette.get_active_index(), 2)