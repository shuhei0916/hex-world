extends GutTest

class_name TestGameLevel

const GameLevelScene = preload("res://scenes/GameLevel.tscn")
const GameLevelClass = preload("res://scripts/game_level.gd")
const GridDisplayClass = preload("res://scripts/grid_display.gd")
const PaletteClass = preload("res://scripts/palette.gd")
const HUDClass = preload("res://scripts/hud.gd")

var game_level

func before_each():
	GridManager.clear_grid()
	# シーンからインスタンス化
	game_level = GameLevelScene.instantiate()
	# ツリーに追加して_readyを走らせ、@onready変数を解決させる
	add_child_autofree(game_level)

func after_each():
	GridManager.clear_grid()

func test_GameLevelはGridDisplayを持つ():
	# GridDisplayは動的生成なので子ノードから探す
	var found = false
	for child in game_level.get_children():
		if child is GridDisplayClass:
			found = true
			break
	assert_true(found, "GameLevel should have a GridDisplay child")

func test_グリッド更新シグナルでGridManagerに登録される():
	var gd = game_level.grid_display
	# @onreadyが効いてない場合、動的生成されたものを探す
	if gd == null:
		for child in game_level.get_children():
			if child is GridDisplayClass:
				gd = child
				break
	
	if gd == null:
		fail_test("GridDisplay not found")
		return

	GridManager.clear_grid()
	gd.create_hex_grid(2)
	assert_true(GridManager.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")

func test_GameLevelはPaletteを持つ():
	assert_not_null(game_level.palette)
	assert_true(game_level.palette is PaletteClass)

func test_GameLevelはHUDを持ちPaletteが注入されている():
	# HUDの存在確認 (@onready var hud が解決されているはず)
	var hud = game_level.hud
	assert_not_null(hud, "HUD node should be linked in GameLevel via @onready")
	
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