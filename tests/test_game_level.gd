extends GutTest

class_name TestGameLevel

const GameLevelClass = preload("res://scripts/game_level.gd")
const GridDisplayClass = preload("res://scripts/grid_display.gd")
const PaletteClass = preload("res://scripts/palette.gd")
const PaletteUIClass = preload("res://scripts/palette_ui.gd")

var game_level

func before_each():
	GridManager.clear_grid()
	game_level = GameLevelClass.new()
	add_child_autofree(game_level)

func after_each():
	GridManager.clear_grid()

func test_GameLevelはGridDisplayを持つ():
	var found = false
	for child in game_level.get_children():
		if child is GridDisplayClass:
			found = true
			break
	assert_true(found, "GameLevel should have a GridDisplay child")

func test_グリッド更新シグナルでGridManagerに登録される():
	# GridDisplayを取得
	var gd = null
	for child in game_level.get_children():
		if child is GridDisplayClass:
			gd = child
			break
	
	if gd == null:
		fail_test("GridDisplay not found")
		return

	# 一旦クリア
	GridManager.clear_grid()
	
	# 手動でグリッド再生成
	gd.create_hex_grid(2)
	
	# GridManagerに登録されたか確認
	assert_true(GridManager.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")

func test_GameLevelはPaletteを持つ():
	assert_not_null(game_level.palette)
	assert_true(game_level.palette is PaletteClass)

func test_GameLevelはPaletteUIを持ちPaletteが注入されている():
	# PaletteUIを探す (CanvasLayerの下にあるかもしれないので再帰的に探すか、既知のパスで)
	var palette_ui = _find_node_by_type(game_level, PaletteUIClass)
	assert_not_null(palette_ui, "PaletteUI should exist in GameLevel")
	if palette_ui:
		assert_eq(palette_ui.palette, game_level.palette, "PaletteUI should have the same Palette instance")

func test_数字キー入力でPaletteの選択が変更される():
	# 初期状態確認
	assert_eq(game_level.palette.get_active_index(), 0)
	
	# KEY_3 (index 2) を入力
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	game_level._unhandled_input(event)
	
	assert_eq(game_level.palette.get_active_index(), 2)

# ヘルパー関数
func _find_node_by_type(root: Node, type):
	if is_instance_of(root, type):
		return root
	for child in root.get_children():
		var result = _find_node_by_type(child, type)
		if result:
			return result
	return null