# gdlint:disable=constant-name
extends GutTest

const HexGrid = preload("res://scenes/components/island/hex_grid.gd")


class TestRegisterAndQuery:
	extends GutTest

	var grid

	func before_each():
		grid = HexGrid.new()

	func test_登録したhexはグリッド内として認識される():
		grid.register_grid_hex(Hex.new(0, 0))
		assert_true(grid.is_inside_grid(Hex.new(0, 0)))

	func test_未登録のhexはグリッド外として認識される():
		assert_false(grid.is_inside_grid(Hex.new(1, 0)))

	func test_occupyしたhexは占有済みとして認識される():
		grid.occupy(Hex.new(0, 0))
		assert_true(grid.is_occupied(Hex.new(0, 0)))

	func test_occupy_manyで複数hexを一括占有できる():
		grid.occupy_many([Hex.new(0, 0), Hex.new(1, 0)])
		assert_true(grid.is_occupied(Hex.new(0, 0)))
		assert_true(grid.is_occupied(Hex.new(1, 0)))


class TestCanPlace:
	extends GutTest

	var grid

	func before_each():
		grid = HexGrid.new()
		# 半径1のグリッドを手動登録
		for q in range(-1, 2):
			var r1 = max(-1, -q - 1)
			var r2 = min(1, -q + 1)
			for r in range(r1, r2 + 1):
				grid.register_grid_hex(Hex.new(q, r))

	func test_グリッド内の空きhexには配置できる():
		var shape = [Hex.new(0, 0)]
		assert_true(grid.can_place(shape, Hex.new(0, 0)))

	func test_グリッド外のhexには配置できない():
		var shape = [Hex.new(0, 0)]
		assert_false(grid.can_place(shape, Hex.new(5, 0)))

	func test_占有済みhexには配置できない():
		grid.occupy(Hex.new(0, 0))
		var shape = [Hex.new(0, 0)]
		assert_false(grid.can_place(shape, Hex.new(0, 0)))

	func test_shapeの一部がグリッド外なら配置できない():
		# base_hex=(1,0) + offset=(1,0) = (2,0) はグリッド外
		var shape = [Hex.new(0, 0), Hex.new(1, 0)]
		assert_false(grid.can_place(shape, Hex.new(1, 0)))


class TestClearGrid:
	extends GutTest

	var grid

	func before_each():
		grid = HexGrid.new()

	func test_clear_gridで登録済みhexが消える():
		grid.register_grid_hex(Hex.new(0, 0))
		grid.clear_grid()
		assert_false(grid.is_inside_grid(Hex.new(0, 0)))

	func test_clear_gridで占有済みhexが消える():
		grid.occupy(Hex.new(0, 0))
		grid.clear_grid()
		assert_false(grid.is_occupied(Hex.new(0, 0)))
