extends GutTest

class_name TestHexBasic

func test_hex_coordinate_constraint():
	# テストリスト項目: Hex座標の制約チェック（q + r + s = 0）
	# q + r + s = 0 が成り立つ有効な座標
	var valid_hex = Hex.new(1, -2, 1)
	assert_true(valid_hex.is_valid(), "Valid hex coordinates should pass constraint check")
	
	# q + r + s != 0 となる無効な座標をテスト
	var invalid_hex = Hex.new(1, 1, 1) 
	assert_false(invalid_hex.is_valid(), "Invalid hex coordinates should fail constraint check")

func test_vector2_usage():
	# テストリスト項目: Vector2の使用（GodotのBuilt-inクラス）
	var point = Vector2(3.5, -2.1)
	assert_almost_eq(point.x, 3.5, 0.001)
	assert_almost_eq(point.y, -2.1, 0.001)