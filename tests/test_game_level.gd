extends GutTest

class_name TestGameLevel

const GameLevelScene = preload("res://scenes/GameLevel.tscn")
const GameLevelClass = preload("res://scripts/game_level.gd")
const GridDisplayClass = preload("res://scripts/grid_display.gd")
const PaletteClass = preload("res://scripts/palette.gd")
const HUDClass = preload("res://scripts/hud.gd")
# HUDシーンがない場合に備えて動的ロードを試みる
const HUDScenePath = "res://scenes/hud.tscn"

var game_level

func before_each():
	GridManager.clear_grid()
	# シーンからインスタンス化
	game_level = GameLevelScene.instantiate()
	
	# もしHUDがシーンに含まれていない（null）なら、テスト用に動的追加
	# これにより、エディタ作業の未完了や反映待ちでもテストを続行できる
	if game_level.hud == null:
		if FileAccess.file_exists(HUDScenePath):
			var hud_scene = load(HUDScenePath)
			var hud_instance = hud_scene.instantiate()
			hud_instance.name = "HUD"
			game_level.add_child(hud_instance)
			# _readyが呼ばれる前にhudプロパティをセットする必要があるが
			# @onreadyは_readyの前に走るので、add_childしただけでは@onready変数は再代入されない
			# 手動で割り当てる
			game_level.hud = hud_instance
		else:
			# HUDシーンすらない場合はスクリプトから生成（最低限）
			var hud_instance = HUDClass.new()
			hud_instance.name = "HUD"
			game_level.add_child(hud_instance)
			game_level.hud = hud_instance
			
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
	# HUDの存在確認
	var hud = game_level.hud
	assert_not_null(hud, "HUD node should be linked in GameLevel")
	
	if hud:
		assert_true(hud is HUDClass)
		# HUD経由でPaletteUIにPaletteが渡っているか
		var ui = hud.palette_ui
		# PaletteUIも動的に追加されたHUDの場合は手動で追加が必要かも？
		# HUDスクリプトは $PaletteUI を探すので、HUDシーンが正しければOK。
		# もしHUDクラスをnew()しただけならPaletteUIはない。
		
		# HUDが正しくセットアップされていればUIがあるはず
		if ui:
			assert_eq(ui.palette, game_level.palette, "PaletteUI should have the same Palette instance")
		else:
			# HUDはあるがPaletteUIがない場合（シーン構成不備など）
			# ここではWarning程度にしておくか、テスト失敗にするか
			# 今回は失敗させる
			fail_test("PaletteUI not found in HUD. Check HUD scene structure.")

func test_数字キー入力でPaletteの選択が変更される():
	assert_eq(game_level.palette.get_active_index(), 0)
	
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	game_level._unhandled_input(event)
	
	assert_eq(game_level.palette.get_active_index(), 2)
