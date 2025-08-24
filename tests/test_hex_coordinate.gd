extends GutTest

const HexCoordinate = preload("res://scripts/hex_coordinate.gd")

func test_hex_coordinate_creation():
	var hex = HexCoordinate.new(1, -1, 0)
	assert_eq(hex.q, 1, "q座標が正しく設定される")
	assert_eq(hex.r, -1, "r座標が正しく設定される")
	assert_eq(hex.s, 0, "s座標が正しく設定される")
	