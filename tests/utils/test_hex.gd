extends GutTest


# 基本構造とデータ型テスト
class TestHexBasics:
	extends GutTest

	func test_hex座標の制約をチェックできる():
		var valid_hex = Hex.new(1, -2, 1)
		assert_true(valid_hex.is_valid())

		var invalid_hex = Hex.new(1, 1, 1)
		assert_false(invalid_hex.is_valid())

	func test_vector2を使用できる():
		var point = Vector2(3.5, -2.1)
		assert_almost_eq(point.x, 3.5, 0.001)
		assert_almost_eq(point.y, -2.1, 0.001)


# 算術演算テスト
class TestArithmetic:
	extends GutTest

	func test_hex座標を加算できる():
		var hex_a = Hex.new(1, -3, 2)
		var hex_b = Hex.new(3, -7, 4)
		var expected = Hex.new(4, -10, 6)
		var result = Hex.add(hex_a, hex_b)
		assert_true(Hex.equals(result, expected))

	func test_hex座標を減算できる():
		var hex_a = Hex.new(1, -3, 2)
		var hex_b = Hex.new(3, -7, 4)
		var expected = Hex.new(-2, 4, -2)
		var result = Hex.subtract(hex_a, hex_b)
		assert_true(Hex.equals(result, expected))

	func test_hex座標をスケールできる():
		var hex_a = Hex.new(2, -3, 1)
		var k = 3
		var expected = Hex.new(6, -9, 3)
		var result = Hex.scale(hex_a, k)
		assert_true(Hex.equals(result, expected))

	func test_同じ座標のhexは等価である():
		var hex_a = Hex.new(1, -2, 1)
		var hex_b = Hex.new(1, -2, 1)
		assert_true(Hex.equals(hex_a, hex_b))

	func test_異なる座標のhexは等価ではない():
		var hex_a = Hex.new(1, -2, 1)
		var hex_c = Hex.new(2, -3, 1)
		assert_false(Hex.equals(hex_a, hex_c))

	func test_hex座標を左回転できる():
		var hex_a = Hex.new(1, -3, 2)
		var expected = Hex.new(-2, -1, 3)
		var result = Hex.rotate_left(hex_a)
		assert_true(Hex.equals(result, expected))

	func test_hex座標を右回転できる():
		var hex_a = Hex.new(1, -3, 2)
		var expected = Hex.new(3, -2, -1)
		var result = Hex.rotate_right(hex_a)
		assert_true(Hex.equals(result, expected), "hex_rotate_right should return correct result")


# 方向・隣接システムテスト
class TestHexDirections:
	extends GutTest

	func test_指定方向のhexベクトルを取得できる():
		var expected = Hex.new(0, -1, 1)
		var result = Hex.direction(2)
		assert_true(Hex.equals(result, expected))

	func test_指定方向の隣接hexを取得できる():
		var hex_center = Hex.new(1, -2, 1)
		var direction = 2
		var expected = Hex.new(1, -3, 2)
		var result = Hex.neighbor(hex_center, direction)
		assert_true(Hex.equals(result, expected))

	func test_指定方向の対角隣接hexを取得できる():
		var hex_center = Hex.new(1, -2, 1)
		var direction = 3
		var expected = Hex.new(-1, -1, 2)
		var result = Hex.diagonal_neighbor(hex_center, direction)
		assert_true(Hex.equals(result, expected))

	func test_文字列から方向ベクトルを取得できる():
		var result = Hex.direction_by_name("E")
		var expected = Hex.new(1, 0, -1)
		assert_true(Hex.equals(result, expected))

	func test_2つのHex間の方向インデックスを取得できる():
		var center = Hex.new(0, 0, 0)
		var dirs = Hex.DIR_NAME_TO_INDEX
		assert_eq(Hex.get_direction_to(center, Hex.new(1, 0, -1)), dirs["E"], "東")
		assert_eq(Hex.get_direction_to(center, Hex.new(1, -1, 0)), dirs["NE"], "北東")
		assert_eq(Hex.get_direction_to(center, Hex.new(0, -1, 1)), dirs["NW"], "北西")
		assert_eq(Hex.get_direction_to(center, Hex.new(-1, 0, 1)), dirs["W"], "西")
		assert_eq(Hex.get_direction_to(center, Hex.new(-1, 1, 0)), dirs["SW"], "南西")
		assert_eq(Hex.get_direction_to(center, Hex.new(0, 1, -1)), dirs["SE"], "南東")

		# 隣接していない場合
		assert_eq(Hex.get_direction_to(center, Hex.new(10, 10)), -1, "隣接していなければ-1")


# 距離・補間システムテスト
class TestHexDistance:
	extends GutTest

	func test_hex座標の長さを計算できる():
		var hex_a = Hex.new(3, -7, 4)
		var expected = 7
		var result = Hex.length(hex_a)
		assert_eq(result, expected)

	func test_hex間の距離を計算できる():
		var hex_a = Hex.new(3, -7, 4)
		var hex_b = Hex.new(0, 0, 0)
		var expected = 7
		var result = Hex.distance(hex_a, hex_b)
		assert_eq(result, expected)

	func test_hex座標を整数に丸められる():
		var hex_float = Hex.new(5.0, -10.0, 5.0)
		var expected = Hex.new(5, -10, 5)
		var result = Hex.round(hex_float)
		assert_true(Hex.equals(result, expected))

	func test_hex座標を線形補間できる():
		var hex_a = Hex.new(0, 0, 0)
		var hex_b = Hex.new(10, -20, 10)
		var t = 0.5
		var expected = Hex.new(5.0, -10.0, 5.0)
		var result = Hex.lerp(hex_a, hex_b, t)
		assert_almost_eq(result.q, expected.q, 0.001)
		assert_almost_eq(result.r, expected.r, 0.001)
		assert_almost_eq(result.s, expected.s, 0.001)

	func test_hex間の線を描画できる():
		var hex_a = Hex.new(0, 0, 0)
		var hex_b = Hex.new(1, -5, 4)
		var result = Hex.linedraw(hex_a, hex_b)
		var expected = [
			Hex.new(0, 0, 0),
			Hex.new(0, -1, 1),
			Hex.new(0, -2, 2),
			Hex.new(1, -3, 2),
			Hex.new(1, -4, 3),
			Hex.new(1, -5, 4)
		]
		assert_eq(
			result.size(), expected.size(), "hex_linedraw should return correct number of hexes"
		)
		for i in range(result.size()):
			assert_true(
				Hex.equals(result[i], expected[i]),
				"hex_linedraw point " + str(i) + " should be correct"
			)


# 2引数コンストラクタテスト
class TestHexTwoArgConstructor:
	extends GutTest

	var test_hex: Hex

	func before_all():
		test_hex = Hex.new(1, 2)

	func test_2引数コンストラクタでs値が自動計算される():
		assert_eq(test_hex.s, -3)

	func test_2引数と3引数コンストラクタが同等である():
		var hex2 = Hex.new(2, -1)
		var hex3 = Hex.new(2, -1, -1)
		assert_true(Hex.equals(hex2, hex3))


# レイアウト・ピクセル変換テスト
class TestLayout:
	extends GutTest

	func test_hexとピクセル座標を相互変換できる():
		var h = Hex.new(3, 4, -7)

		# flat orientation layout
		var flat = Layout.new(Layout.layout_flat, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		var flat_result = Layout.pixel_to_hex_rounded(flat, Layout.hex_to_pixel(flat, h))
		assert_true(
			Hex.equals(h, flat_result),
			"Layout flat orientation roundtrip should preserve hex coordinates"
		)

		# pointy orientation layout
		var pointy = Layout.new(Layout.layout_pointy, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		var pointy_result = Layout.pixel_to_hex_rounded(pointy, Layout.hex_to_pixel(pointy, h))
		assert_true(
			Hex.equals(h, pointy_result),
			"Layout pointy orientation roundtrip should preserve hex coordinates"
		)
