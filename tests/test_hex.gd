extends GutTest

class_name TestHex

# 基本構造とデータ型テスト
class TestHexBasics:
	extends GutTest
	
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

# 算術演算テスト
class TestArithmetic:
	extends GutTest
	
	func test_hex_add():
		# テストリスト項目: hex_add関数の実装とテスト
		# Python版: hex_add(Hex(1, -3, 2), Hex(3, -7, 4)) -> Hex(4, -10, 6)
		var hex_a = Hex.new(1, -3, 2)
		var hex_b = Hex.new(3, -7, 4)
		var expected = Hex.new(4, -10, 6)
		var result = Hex.add(hex_a, hex_b)
		assert_true(Hex.equals(result, expected), "hex_add should return correct result")

	func test_hex_subtract():
		# テストリスト項目: hex_subtract関数の実装とテスト
		# Python版: hex_subtract(Hex(1, -3, 2), Hex(3, -7, 4)) -> Hex(-2, 4, -2)
		var hex_a = Hex.new(1, -3, 2)
		var hex_b = Hex.new(3, -7, 4)
		var expected = Hex.new(-2, 4, -2)
		var result = Hex.subtract(hex_a, hex_b)
		assert_true(Hex.equals(result, expected), "hex_subtract should return correct result")

	func test_hex_scale():
		# テストリスト項目: hex_scale関数の実装とテスト  
		# Python版: hex_scale(a, k) return Hex(a.q * k, a.r * k, a.s * k)
		var hex_a = Hex.new(2, -3, 1)
		var k = 3
		var expected = Hex.new(6, -9, 3)
		var result = Hex.scale(hex_a, k)
		assert_true(Hex.equals(result, expected), "hex_scale should return correct result")

	func test_hex_equals_same_coordinates():
		# Hex等価判定: 同じ座標のテスト
		# Python版: equal_hex関数 a.q == b.q and a.s == b.s and a.r == b.r
		var hex_a = Hex.new(1, -2, 1)
		var hex_b = Hex.new(1, -2, 1)  # 同じ座標
		assert_true(Hex.equals(hex_a, hex_b), "Same coordinates should be equal")

	func test_hex_equals_different_coordinates():
		# Hex等価判定: 異なる座標のテスト
		var hex_a = Hex.new(1, -2, 1)
		var hex_c = Hex.new(2, -3, 1)  # 異なる座標
		assert_false(Hex.equals(hex_a, hex_c), "Different coordinates should not be equal")

	func test_hex_rotate_left():
		# テストリスト項目: hex_rotate_left関数の実装とテスト
		# Python版: hex_rotate_left(a) return Hex(-a.s, -a.q, -a.r)
		var hex_a = Hex.new(1, -3, 2)
		var expected = Hex.new(-2, -1, 3)  # (-a.s, -a.q, -a.r) = (-2, -1, 3)
		var result = Hex.rotate_left(hex_a)
		assert_true(Hex.equals(result, expected), "hex_rotate_left should return correct result")

	func test_hex_rotate_right():
		# テストリスト項目: hex_rotate_right関数の実装とテスト
		# Python版: hex_rotate_right(a) return Hex(-a.r, -a.s, -a.q)
		var hex_a = Hex.new(1, -3, 2)
		var expected = Hex.new(3, -2, -1)  # (-a.r, -a.s, -a.q) = (3, -2, -1)
		var result = Hex.rotate_right(hex_a)
		assert_true(Hex.equals(result, expected), "hex_rotate_right should return correct result")

# 方向・隣接システムテスト
class TestHexDirections:
	extends GutTest
	
	func test_hex_direction():
		# テストリスト項目: hex_direction関数の実装とテスト
		# Python版: def hex_direction(direction): return hex_directions[direction]
		var expected = Hex.new(0, -1, 1)  # hex_directions[2]
		var result = Hex.direction(2)
		assert_true(Hex.equals(result, expected), "Direction 2 should return Hex(0, -1, 1)")

	func test_hex_neighbor():
		# テストリスト項目: hex_neighbor関数の実装とテスト
		# Python版: def hex_neighbor(hex, direction): return hex_add(hex, hex_direction(direction))
		var hex_center = Hex.new(1, -2, 1)
		var direction = 2  # hex_direction(2) = Hex(0, -1, 1)
		var expected = Hex.new(1, -3, 2)  # hex_add(Hex(1, -2, 1), Hex(0, -1, 1))
		var result = Hex.neighbor(hex_center, direction)
		assert_true(Hex.equals(result, expected), "hex_neighbor should return correct neighbor")

	func test_hex_diagonal_neighbor():
		# テストリスト項目: hex_diagonal_neighbor関数の実装とテスト
		# Python版: def hex_diagonal_neighbor(hex, direction): return hex_add(hex, hex_diagonals[direction])
		# hex_diagonals[3] = Hex(-2, 1, 1)
		var hex_center = Hex.new(1, -2, 1)
		var direction = 3
		var expected = Hex.new(-1, -1, 2)  # hex_add(Hex(1, -2, 1), Hex(-2, 1, 1))
		var result = Hex.diagonal_neighbor(hex_center, direction)
		assert_true(Hex.equals(result, expected), "hex_diagonal_neighbor should return correct diagonal neighbor")

# 距離・補間システムテスト
class TestHexDistance:
	extends GutTest
	
	func test_hex_length():
		# テストリスト項目: hex_length関数の実装とテスト
		# Python版: def hex_length(hex): return (abs(hex.q) + abs(hex.r) + abs(hex.s)) // 2
		var hex_a = Hex.new(3, -7, 4)
		var expected = 7  # (abs(3) + abs(-7) + abs(4)) // 2 = (3 + 7 + 4) // 2 = 14 // 2 = 7
		var result = Hex.length(hex_a)
		assert_eq(result, expected, "hex_length should return correct length")

	func test_hex_distance():
		# テストリスト項目: hex_distance関数の実装とテスト
		# Python版: def hex_distance(a, b): return hex_length(hex_subtract(a, b))
		var hex_a = Hex.new(3, -7, 4)
		var hex_b = Hex.new(0, 0, 0)
		var expected = 7  # hex_length(hex_subtract(Hex(3, -7, 4), Hex(0, 0, 0))) = hex_length(Hex(3, -7, 4)) = 7
		var result = Hex.distance(hex_a, hex_b)
		assert_eq(result, expected, "hex_distance should return correct distance")

	func test_hex_round():
		# テストリスト項目: hex_round関数の実装とテスト
		# Python版のテスト: hex_round(hex_lerp(Hex(0, 0, 0), Hex(10, -20, 10), 0.5)) -> Hex(5, -10, 5)
		var hex_float = Hex.new(5.0, -10.0, 5.0)  # 既に整数値なので丸めても同じ
		var expected = Hex.new(5, -10, 5)
		var result = Hex.round(hex_float)
		assert_true(Hex.equals(result, expected), "hex_round should return correct rounded hex")

	func test_hex_lerp():
		# テストリスト項目: hex_lerp関数の実装とテスト
		# Python版: hex_lerp(a, b, t) return Hex(a.q * (1.0 - t) + b.q * t, a.r * (1.0 - t) + b.r * t, a.s * (1.0 - t) + b.s * t)
		var hex_a = Hex.new(0, 0, 0)
		var hex_b = Hex.new(10, -20, 10)
		var t = 0.5
		var expected = Hex.new(5.0, -10.0, 5.0)  # 中点の浮動小数点座標
		var result = Hex.lerp(hex_a, hex_b, t)
		assert_almost_eq(result.q, expected.q, 0.001, "hex_lerp q component should be correct")
		assert_almost_eq(result.r, expected.r, 0.001, "hex_lerp r component should be correct") 
		assert_almost_eq(result.s, expected.s, 0.001, "hex_lerp s component should be correct")

	func test_hex_linedraw():
		# テストリスト項目: hex_linedraw関数の実装とテスト
		# Python版テストと同じ: hex_linedraw(Hex(0, 0, 0), Hex(1, -5, 4))
		var hex_a = Hex.new(0, 0, 0)
		var hex_b = Hex.new(1, -5, 4)
		var result = Hex.linedraw(hex_a, hex_b)
		var expected = [Hex.new(0, 0, 0), Hex.new(0, -1, 1), Hex.new(0, -2, 2), Hex.new(1, -3, 2), Hex.new(1, -4, 3), Hex.new(1, -5, 4)]
		assert_eq(result.size(), expected.size(), "hex_linedraw should return correct number of hexes")
		for i in range(result.size()):
			assert_true(Hex.equals(result[i], expected[i]), "hex_linedraw point " + str(i) + " should be correct")

# 2引数コンストラクタテスト
class TestHexTwoArgConstructor:
	extends GutTest
	
	var test_hex: Hex
	
	func before_all():
		test_hex = Hex.new(1, 2)
	
	func test_two_arg_constructor_s_calculation():
		assert_eq(test_hex.s, -3)
	
	func test_two_arg_vs_three_arg_equivalence():
		var hex2 = Hex.new(2, -1)
		var hex3 = Hex.new(2, -1, -1)
		assert_true(Hex.equals(hex2, hex3))

# レイアウト・ピクセル変換テスト
class TestLayout:
	extends GutTest
	
	func test_layout():
		# テストリスト項目: test_layout関数のテスト
		# Python版: Layoutでhex↔pixel変換の往復テスト
		var h = Hex.new(3, 4, -7)
		
		# flat orientation layout
		var flat = Layout.new(Layout.layout_flat, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		var flat_result = Layout.pixel_to_hex_rounded(flat, Layout.hex_to_pixel(flat, h))
		assert_true(Hex.equals(h, flat_result), "Layout flat orientation roundtrip should preserve hex coordinates")
		
		# pointy orientation layout
		var pointy = Layout.new(Layout.layout_pointy, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		var pointy_result = Layout.pixel_to_hex_rounded(pointy, Layout.hex_to_pixel(pointy, h))
		assert_true(Hex.equals(h, pointy_result), "Layout pointy orientation roundtrip should preserve hex coordinates")