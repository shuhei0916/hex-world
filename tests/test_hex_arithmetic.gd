extends GutTest

class_name TestHexArithmetic

func test_hex_add():
	# テストリスト項目: hex_add関数の実装とテスト
	# Python版: hex_add(Hex(1, -3, 2), Hex(3, -7, 4)) -> Hex(4, -10, 6)
	var hex_a = Hex.new(1, -3, 2)
	var hex_b = Hex.new(3, -7, 4)
	var result = Hex.add(hex_a, hex_b)
	assert_eq(result.q, 4)
	assert_eq(result.r, -10)
	assert_eq(result.s, 6)

func test_hex_subtract():
	# テストリスト項目: hex_subtract関数の実装とテスト
	# Python版: hex_subtract(Hex(1, -3, 2), Hex(3, -7, 4)) -> Hex(-2, 4, -2)
	var hex_a = Hex.new(1, -3, 2)
	var hex_b = Hex.new(3, -7, 4)
	var result = Hex.subtract(hex_a, hex_b)
	assert_eq(result.q, -2)
	assert_eq(result.r, 4)
	assert_eq(result.s, -2)

func test_hex_scale():
	# テストリスト項目: hex_scale関数の実装とテスト  
	# Python版: hex_scale(a, k) return Hex(a.q * k, a.r * k, a.s * k)
	var hex_a = Hex.new(2, -3, 1)
	var k = 3
	var result = Hex.scale(hex_a, k)
	assert_eq(result.q, 6)
	assert_eq(result.r, -9)
	assert_eq(result.s, 3)

func test_hex_equals():
	# Hex等価判定の実装とテスト
	# Python版: equal_hex関数 a.q == b.q and a.s == b.s and a.r == b.r
	var hex_a = Hex.new(1, -2, 1)
	var hex_b = Hex.new(1, -2, 1)  # 同じ座標
	var hex_c = Hex.new(2, -3, 1)  # 異なる座標
	
	assert_true(Hex.equals(hex_a, hex_b), "Same coordinates should be equal")
	assert_false(Hex.equals(hex_a, hex_c), "Different coordinates should not be equal")