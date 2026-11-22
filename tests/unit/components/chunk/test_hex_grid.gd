extends GutTest

# HexGrid は chunk にどのマスがあるか（盤面の形）だけを持つ

var grid: HexGrid


func before_each():
	grid = HexGrid.new()


func test_入れたマスはグリッドの内側():
	var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	grid.set_hexes(hexes)
	assert_true(grid.is_inside_grid(Vector2i(0, 0)))
	assert_true(grid.is_inside_grid(Vector2i(1, 0)))


func test_入れていないマスはグリッドの外():
	assert_false(grid.is_inside_grid(Vector2i(1, 0)))


func test_入れ直すと前のマスは残らない():
	var before: Array[Vector2i] = [Vector2i(0, 0), Vector2i(5, 0)]
	var after: Array[Vector2i] = [Vector2i(0, 0)]
	grid.set_hexes(before)
	grid.set_hexes(after)
	assert_false(grid.is_inside_grid(Vector2i(5, 0)))
	assert_true(grid.is_inside_grid(Vector2i(0, 0)))
