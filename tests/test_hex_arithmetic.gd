extends GutTest

class_name TestHexArithmetic

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