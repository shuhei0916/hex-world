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