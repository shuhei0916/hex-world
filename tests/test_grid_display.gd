extends GutTest

# GridDisplayのテスト
class_name TestGridDisplay

const GridDisplayClass = preload("res://scripts/grid_display.gd")

func test_grid_display_class_exists():
	var grid_display = GridDisplayClass.new()
	assert_not_null(grid_display)

func test_create_hex_grid():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(3)
	var grid_size = grid_display.get_grid_hex_count()
	assert_true(grid_size > 0)

func test_hex_to_pixel_conversion():
	var grid_display = GridDisplayClass.new()
	var test_hex = Hex.new(1, -1)
	var pixel_pos = grid_display.hex_to_pixel(test_hex)
	assert_not_null(pixel_pos)

func test_grid_manager_integration():
	var grid_display = GridDisplayClass.new()
	grid_display.create_hex_grid(2)
	grid_display.register_grid_with_manager()
	
	# GridManagerにグリッドが登録されているか確認
	var test_hex = Hex.new(0, 0)
	var is_registered = GridManager.is_inside_grid(test_hex)
	assert_true(is_registered)

func before_each():
	if GridManager:
		GridManager.clear_grid()