extends GutTest
class_name TestMain

const MainScene = preload("res://scenes/main/main.tscn")
const MainClass = preload("res://scenes/main/main.gd")
const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")
const PaletteClass = preload("res://scenes/ui/palette/palette.gd")
const HUDClass = preload("res://scenes/ui/hud/hud.gd")

var main_node

func before_each():
	main_node = MainScene.instantiate()
	add_child_autofree(main_node)

func after_each():
	pass

func test_MainはGridManagerを持つ():
	assert_not_null(main_node.grid_manager)
	assert_true(main_node.grid_manager is GridManagerClass)

func test_グリッド更新シグナルでGridManagerに登録される():
	var gm = main_node.grid_manager
	if gm == null:
		fail_test("GridManager not found")
		return

	gm.clear_grid()
	
	gm.create_hex_grid(2)
	assert_true(gm.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")

func test_MainはPaletteを持つ():
	assert_not_null(main_node.palette)
	assert_true(main_node.palette is PaletteClass)

func test_MainはHUDを持ちPaletteが注入されている():
	var hud = main_node.hud
	assert_not_null(hud, "HUD node should be linked in Main (Check if HUD is added to Main scene)")
	
	if hud:
		assert_true(hud is HUDClass)
		var ui = hud.palette_ui
		assert_not_null(ui, "PaletteUI should exist in HUD")
		if ui:
			assert_eq(ui.palette, main_node.palette, "PaletteUI should have the same Palette instance")

func test_数字キー入力でPaletteの選択が変更される():
	assert_eq(main_node.palette.get_active_index(), 0)
	
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	main_node._unhandled_input(event)
	
	assert_eq(main_node.palette.get_active_index(), 2)
