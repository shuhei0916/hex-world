extends GutTest

# MainScene - 動作するドキュメント
# ゲームのメインシーンとして、hex座標変換・デバッグ機能を提供する
class_name TestMainScene

const MainScene = preload("res://scenes/MainScene.tscn")
var scene_instance: Node2D

func before_each():
	scene_instance = MainScene.instantiate()

func after_each():
	scene_instance.queue_free()

func test_原点のマウス座標は中央hexに変換される():
	var mouse_pos = Vector2(0.0, 0.0)
	var hex_coord = scene_instance.get_hex_at_mouse_position(mouse_pos)
	
	assert_eq(hex_coord.q, 0)
	assert_eq(hex_coord.r, 0)

func test_デバッグモードは初期状態でOFFである():
	assert_false(scene_instance.debug_mode)

func test_デバッグモードはトグルで切り替えられる():
	scene_instance.toggle_debug_mode()
	assert_true(scene_instance.debug_mode)
	
	scene_instance.toggle_debug_mode()
	assert_false(scene_instance.debug_mode)

func test_デバッグモードONで各hexに座標が表示される():
	add_child(scene_instance)
	
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	
	assert_not_null(coord_label)
	assert_true(coord_label.visible)
	assert_true(coord_label.text.begins_with("("))

func test_デバッグモードOFFで座標表示が隠れる():
	add_child(scene_instance)
	
	# 一度表示してから隠す
	scene_instance.debug_mode = true
	scene_instance.update_hex_overlay_display()
	scene_instance.debug_mode = false
	scene_instance.update_hex_overlay_display()
	
	var grid_display = scene_instance.get_node("GridDisplay")
	var first_hex_tile = grid_display.get_child(0)
	var coord_label = first_hex_tile.get_node_or_null("CoordLabel")
	
	assert_false(coord_label.visible)


func test_マウス座標変換が一貫して正確に行われる():
	scene_instance._ready()
	add_child(scene_instance)
	
	var grid_display = scene_instance.grid_display
	if grid_display and grid_display.layout:
		var target_hex = Hex.new(1, 0)
		var expected_pixel_position = Layout.hex_to_pixel(grid_display.layout, target_hex)
		
		var actual_hex = scene_instance.get_hex_at_mouse_position(expected_pixel_position)
		
		var distance_to_expected = Hex.distance(actual_hex, target_hex)
		assert_true(distance_to_expected == 0, "座標変換の精度が期待値から外れています: 期待 %s 実際 %s" % [target_hex, actual_hex])

func test_左クリックでBARピースが配置される():
	GridManager.clear_grid()
	scene_instance._ready()
	add_child(scene_instance)
	
	var base_hex = Hex.new(0, 0)
	var click_pos = scene_instance.grid_display.hex_to_pixel(base_hex)
	scene_instance.handle_grid_click(click_pos)
	
	var piece_data = scene_instance.palette_ui.get_palette().get_piece_data_for_slot(0)
	var shape: Array = piece_data["shape"]
	for offset in shape:
		var target_hex = Hex.add(base_hex, offset)
		assert_true(GridManager.is_occupied(target_hex), "Hex %s should be occupied after placement" % target_hex)

func test_占有済みの位置には再配置できない():
	GridManager.clear_grid()
	scene_instance._ready()
	add_child(scene_instance)
	
	var base_hex = Hex.new(0, 0)
	var click_pos = scene_instance.grid_display.hex_to_pixel(base_hex)
	scene_instance.handle_grid_click(click_pos)
	
	var piece_data = scene_instance.palette_ui.get_palette().get_piece_data_for_slot(0)
	var shape: Array = piece_data["shape"]
	assert_false(GridManager.can_place(shape, base_hex))

func test_ピースを切り替えると配置される形状が変わる():
	GridManager.clear_grid()
	scene_instance._ready()
	add_child(scene_instance)
	
	var palette = scene_instance.palette_ui.get_palette()
	palette.handle_number_key_input(KEY_3) # PISTOL
	
	var base_hex = Hex.new(0, 0)
	var click_pos = scene_instance.grid_display.hex_to_pixel(base_hex)
	scene_instance.handle_grid_click(click_pos)
	
	var piece_data = palette.get_piece_data_for_slot(2)
	var shape: Array = piece_data["shape"]
	for offset in shape:
		var target_hex = Hex.add(base_hex, offset)
		assert_true(GridManager.is_occupied(target_hex), "Hex %s should be occupied for selected piece" % target_hex)


class TestGridBounds:
	extends GutTest
	
	const MainScene = preload("res://scenes/MainScene.tscn")
	var scene_instance: Node2D
	var grid_display: GridDisplay
	
	func before_each():
		scene_instance = MainScene.instantiate()
		scene_instance._ready()
		grid_display = scene_instance.grid_display
	
	func after_each():
		scene_instance.queue_free()
	
	func test_グリッド中央のhex座標は境界内と判定される():
		var center_hex = Hex.new(0, 0)
		assert_true(grid_display.is_within_bounds(center_hex))
	
	func test_グリッド境界上のhex座標は境界内と判定される():
		var boundary_hex = Hex.new(4, 0)
		assert_true(grid_display.is_within_bounds(boundary_hex))
	
	func test_グリッド境界外のhex座標は境界外と判定される():
		var outside_hex = Hex.new(5, 0)
		assert_false(grid_display.is_within_bounds(outside_hex))
	
	func test_負の座標でも境界チェックが正しく動作する():
		var inside_negative = Hex.new(-3, 2)
		var outside_negative = Hex.new(-5, 1)
		
		assert_true(grid_display.is_within_bounds(inside_negative))
		assert_false(grid_display.is_within_bounds(outside_negative))
	
	func test_グリッド半径設定が境界判定に反映される():
		grid_display.create_hex_grid(2)
		
		var inside_small = Hex.new(1, 1)
		var outside_small = Hex.new(3, 0)
		
		assert_true(grid_display.is_within_bounds(inside_small))
		assert_false(grid_display.is_within_bounds(outside_small))
