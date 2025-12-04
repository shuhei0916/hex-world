extends GutTest
class_name TestMain

const MainScene = preload("res://scenes/main/main.tscn")
const MainClass = preload("res://scenes/main/main.gd")
const GridManagerClass = preload("res://scenes/components/grid/grid_manager.gd")
const PaletteClass = preload("res://scenes/ui/palette/palette.gd")
const HUDClass = preload("res://scenes/ui/hud/hud.gd")
const HexTileScript = preload("res://scenes/components/hex_tile/hex_tile.gd")

var main: MainClass

func before_each():
	main = MainScene.instantiate()
	add_child_autofree(main)

func after_each():
	pass

func test_MainはGridManagerを持つ():
	assert_not_null(main.grid_manager)
	assert_true(main.grid_manager is GridManagerClass)

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
	assert_true(main.palette is PaletteClass)

func test_MainはHUDを持ちPaletteが注入されている():
	var hud = main.hud
	assert_not_null(hud, "HUD node should be linked in Main (Check if HUD is added to Main scene)")
	
	if hud:
		assert_true(hud is HUDClass)
		var ui = hud.palette_ui
		assert_not_null(ui, "PaletteUI should exist in HUD")
		if ui:
			assert_eq(ui.palette, main.palette, "PaletteUI should have the same Palette instance")

func test_数字キー入力でPaletteの選択が変更される():
	assert_eq(main.palette.get_active_index(), 0)
	
	var event = InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	main._unhandled_input(event)
	
	assert_eq(main.palette.get_active_index(), 2)

func test_選択したピースのプレビューがMainに生成される():
	# ピースを選択
	main.palette.select_slot(0) # BARピースを選択
	
	# プレビュー層にプレビューピースが生成されていることを確認
	var preview_root = main.get_node_or_null("PreviewLayer/CurrentPiecePreview")
	assert_not_null(preview_root, "PreviewLayer/CurrentPiecePreview node should be generated in Main")
	
	# 選択されたピースの形状を取得
	var selected_piece_data = main.palette.get_piece_data_for_slot(0)
	var expected_hex_count = selected_piece_data.shape.size()
	
	# プレビューピースの子ノード（HexTileのインスタンス）の数を確認
	assert_eq(preview_root.get_child_count(), expected_hex_count, "Preview piece should have correct number of HexTiles")
	
	# 各子ノードがHexTileのインスタンスであることも確認（オプション）
	for child in preview_root.get_children():
		assert_true(child is HexTileScript, "Each preview child should be a HexTile instance")

func test_指定したHexに選択中のピースを配置できる():
	# ピースを選択
	main.palette.select_slot(0) # BARピースを選択
	
	# 配置対象となるHex座標
	var target_hex = Hex.new(0, 0)
	
	# 配置前にGridManagerがそのHexを占有していないことを確認
	var piece_data_pre = main.palette.get_piece_data_for_slot(0)
	for offset_hex_pre in piece_data_pre["shape"]:
		var check_hex_pre = Hex.add(target_hex, offset_hex_pre)
		assert_false(main.grid_manager.is_occupied(check_hex_pre), "Hex at %s should not be occupied before placement" % check_hex_pre.to_string())
	
	# ピースを配置
	var placed_successfully = main.place_selected_piece(target_hex)
	assert_true(placed_successfully, "Piece should be placed successfully")
	
	# 配置後、GridManagerがそのHexを占有していることを確認
	var piece_data_post = main.palette.get_piece_data_for_slot(0)
	for offset_hex_post in piece_data_post["shape"]:
		var placed_hex = Hex.add(target_hex, offset_hex_post)
		assert_true(main.grid_manager.is_occupied(placed_hex), "Hex at %s should be occupied after placement" % placed_hex.to_string())
