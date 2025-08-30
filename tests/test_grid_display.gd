extends GutTest

# GridDisplayのテスト
class_name TestGridDisplay

const GridDisplayClass = preload("res://scripts/grid_display.gd")

func test_GridDisplayクラスが存在する():
	var grid_display = GridDisplayClass.new()
	assert_not_null(grid_display)

func test_指定半径でhexグリッドを作成できる():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(3)
	var grid_size = grid_display.get_grid_hex_count()
	assert_true(grid_size > 0)

func test_hex座標をピクセル座標に変換できる():
	var grid_display = GridDisplayClass.new()
	var test_hex = Hex.new(1, -1)
	var pixel_pos = grid_display.hex_to_pixel(test_hex)
	assert_not_null(pixel_pos)

func test_GridManagerと連携できる():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(2)
	grid_display.register_grid_with_manager()
	
	var test_hex = Hex.new(0, 0)
	var is_registered = GridManager.is_inside_grid(test_hex)
	assert_true(is_registered)

func test_draw_gridを例外なく呼び出せる():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(2)
	grid_display.draw_grid()
	assert_true(true)

func test_draw_gridで子ノードを生成できる():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(1)
	grid_display.draw_grid()
	assert_eq(grid_display.get_child_count(), 7)

func before_each():
	if GridManager:
		GridManager.clear_grid()