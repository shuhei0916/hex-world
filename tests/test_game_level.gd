extends GutTest

class_name TestGameLevel

const GameLevelClass = preload("res://scripts/game_level.gd")
const GridDisplayClass = preload("res://scripts/grid_display.gd")

var game_level
var grid_display

func before_each():
	GridManager.clear_grid()
	game_level = GameLevelClass.new()
	# GridDisplayはGameLevelの子として生成されることを期待
	# モックではなく実物を使う（統合テストに近い）

func after_each():
	if is_instance_valid(game_level):
		game_level.free()
	GridManager.clear_grid()

func test_GameLevelはGridDisplayを持つ():
	# GameLevelの実装次第だが、_readyなどでGridDisplayを探すか生成するはず
	# ここでは単純に子ノードにあるかチェック
	add_child_autofree(game_level)
	
	var found = false
	for child in game_level.get_children():
		if child is GridDisplayClass:
			found = true
			break
	assert_true(found, "GameLevel should have a GridDisplay child")

func test_グリッド更新シグナルでGridManagerに登録される():
	add_child_autofree(game_level)
	
	# GridDisplayを取得
	var gd = null
	for child in game_level.get_children():
		if child is GridDisplayClass:
			gd = child
			break
	
	if gd == null:
		fail_test("GridDisplay not found")
		return

	# シグナルを強制発火させるか、create_hex_gridを呼ぶ
	# GridDisplayは_readyで初期描画を行うので、すでに登録されている可能性がある
	
	# 一旦クリア
	GridManager.clear_grid()
	
	# 手動でグリッド再生成
	gd.create_hex_grid(2)
	
	# GridManagerに登録されたか確認
	# 半径2のグリッドは19個のhexを持つ
	assert_true(GridManager.is_inside_grid(Hex.new(0, 0)), "Center hex should be registered")
	assert_true(GridManager.is_inside_grid(Hex.new(2, 0)), "Edge hex should be registered")
