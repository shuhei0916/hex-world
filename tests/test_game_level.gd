extends GutTest

class_name TestGameLevel

const GameLevelScene = preload("res://scenes/main/GameLevel.tscn")
const GameLevelClass = preload("res://scenes/main/game_level.gd")
const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")
const PaletteClass = preload("res://scenes/ui/palette/palette.gd")
const HUDClass = preload("res://scenes/ui/hud/hud.gd")

var game_level

func before_each():
	game_level = GameLevelScene.instantiate()
	add_child_autofree(game_level)

func after_each():
	pass

func test_GameLevelはGridManagerを持つ():
	assert_not_null(game_level.grid_manager)
	assert_true(game_level.grid_manager is GridManagerClass)

func test_グリッド更新シグナルでGridManagerに登録される():
	var gm = game_level.grid_manager
	if gm == null:
		fail_test("GridManager not found")
		return

	# GridManagerは自身のclear_gridを持つ
	gm.clear_grid()
	
	# create_hex_gridを呼ぶことで、gm._registered_hexesにhexが登録される
	gm.create_hex_grid(2)
	assert_true(gm.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")

func test_GameLevelはPaletteを持つ():
	assert_not_null(game_level.palette)
	assert_true(game_level.palette is PaletteClass)

func test_GameLevelはHUDを持ちPaletteが注入されている():
	# HUDの存在確認 (@onready var hud が解決されているはず)
	var hud = game_level.hud
	assert_not_null(hud, "HUD node should be linked in GameLevel (Check if HUD is added to GameLevel scene)")
	
	if hud:
		assert_true(hud is HUDClass)
		# HUD経由でPaletteUIにPaletteが渡っているか
		var ui = hud.palette_ui
		assert_not_null(ui, "PaletteUI should exist in HUD")
		if ui:
			assert_eq(ui.palette, game_level.palette, "PaletteUI should have the same Palette instance")

func test_数字キー入力でPaletteの選択が変更される():
	assert_eq(game_level.palette.get_active_index(), 0)
	
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	game_level._unhandled_input(event)
	
	assert_eq(game_level.palette.get_active_index(), 2)