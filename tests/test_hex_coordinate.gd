extends GutTest

const HexCoordinate = preload("res://scripts/hex_coordinate.gd")

func test_hex_coordinate_creation():
	var hex = HexCoordinate.new(1, -1, 0)
	assert_eq(hex.q, 1, "q座標が正しく設定される")
	assert_eq(hex.r, -1, "r座標が正しく設定される")
	assert_eq(hex.s, 0, "s座標が正しく設定される")

func test_hex_coordinate_constraint():
	var hex = HexCoordinate.new(1, -1, 0)
	assert_true(hex.is_valid(), "有効な座標では制約 q + r + s = 0 が満たされる")

func test_hex_coordinate_addition():
	var hex1 = HexCoordinate.new(1, -1, 0)
	var hex2 = HexCoordinate.new(0, 1, -1)
	var result = hex1.add(hex2)
	assert_eq(result.q, 1, "加算結果のq座標が正しい")
	assert_eq(result.r, 0, "加算結果のr座標が正しい")
	assert_eq(result.s, -1, "加算結果のs座標が正しい")
	