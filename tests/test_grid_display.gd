extends GutTest

# GridDisplay - 動作するドキュメント
# hex座標系の数学的精度と視覚化機能を提供する
class_name TestGridDisplay

const GridDisplayClass = preload("res://scripts/grid_display.gd")

func test_半径1のグリッドは7個のhexを生成する():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(1)
	
	assert_eq(grid_display.get_grid_hex_count(), 7)

func test_半径3のグリッドは37個のhexを生成する():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(3)
	
	assert_eq(grid_display.get_grid_hex_count(), 37)

func test_hex座標1マイナス1は正確なピクセル位置に変換される():
	var grid_display = GridDisplayClass.new()
	var test_hex = Hex.new(1, -1)
	
	var pixel_pos = grid_display.hex_to_pixel(test_hex)
	
	# レイアウト設定(42.0, 42.0)での実際の期待値
	assert_almost_eq(pixel_pos.x, 36.373, 0.01)
	assert_almost_eq(pixel_pos.y, -63.0, 0.01)

func test_中央hexはGridManagerに正しく登録される():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(2)
	grid_display.register_grid_with_manager()
	
	var center_hex = Hex.new(0, 0)
	assert_true(GridManager.is_inside_grid(center_hex))

func test_半径1グリッドの描画で7つの子ノードが生成される():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(1)
	
	grid_display.draw_grid()
	
	assert_eq(grid_display.get_child_count(), 7)

func before_each():
	if GridManager:
		GridManager.clear_grid()
