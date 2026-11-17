extends GutTest

## ヘックスの座標は軸座標（q, r）を Vector2i(q, r) で持つ。
## 足し算・引き算・比較は Vector2i の演算子をそのまま使い、Hex はヘックスならではの計算だけを持つ。


class TestCoordinates:
	extends GutTest

	func test_3つ目の座標sは_qとrを足して符号を変えたもの():
		assert_eq(Hex.s(Vector2i(1, 2)), -3)
		assert_eq(Hex.s(Vector2i(0, 0)), 0)

	func test_座標を左回転できる():
		assert_eq(Hex.rotate_left(Vector2i(1, -3)), Vector2i(-2, -1))

	func test_座標を右回転できる():
		assert_eq(Hex.rotate_right(Vector2i(1, -3)), Vector2i(3, -2))

	func test_右に6回まわすと元に戻る():
		var hex := Vector2i(2, -5)
		var rotated := hex
		for i in range(6):
			rotated = Hex.rotate_right(rotated)
		assert_eq(rotated, hex)

	func test_ずれを右回りに指定した回数だけ回転できる():
		assert_eq(Hex.from_offset_rotated(Vector2i(1, -3), 0), Vector2i(1, -3))
		assert_eq(Hex.from_offset_rotated(Vector2i(1, -3), 1), Vector2i(3, -2))
		assert_eq(Hex.from_offset_rotated(Vector2i(1, -3), 2), Hex.rotate_right(Vector2i(3, -2)))


class TestDirections:
	extends GutTest

	func test_指定方向のベクトルを取得できる():
		assert_eq(Hex.direction(2), Vector2i(0, -1))

	func test_方向は東から反時計回りに6つ並ぶ():
		var names = Hex.DIR_NAME_TO_INDEX
		assert_eq(Hex.direction(names["E"]), Vector2i(1, 0))
		assert_eq(Hex.direction(names["NE"]), Vector2i(1, -1))
		assert_eq(Hex.direction(names["NW"]), Vector2i(0, -1))
		assert_eq(Hex.direction(names["W"]), Vector2i(-1, 0))
		assert_eq(Hex.direction(names["SW"]), Vector2i(-1, 1))
		assert_eq(Hex.direction(names["SE"]), Vector2i(0, 1))

	func test_指定方向の隣のマスを取得できる():
		assert_eq(Hex.neighbor(Vector2i(1, -2), 2), Vector2i(1, -3))

	func test_指定方向の対角の隣のマスを取得できる():
		assert_eq(Hex.diagonal_neighbor(Vector2i(1, -2), 3), Vector2i(-1, -1))

	func test_隣接する6マスを返す():
		var neighbors := Hex.neighbors(Vector2i(0, 0))

		assert_eq(neighbors.size(), 6)
		for expected in [
			Vector2i(1, 0),
			Vector2i(1, -1),
			Vector2i(0, -1),
			Vector2i(-1, 0),
			Vector2i(-1, 1),
			Vector2i(0, 1),
		]:
			assert_has(neighbors, expected)

	func test_隣のマスへの方向の番号を取得できる():
		var center := Vector2i(0, 0)
		for i in range(6):
			assert_eq(Hex.get_direction_to(center, Hex.direction(i)), i)

	func test_隣接していないマスへの方向は無い():
		assert_eq(Hex.get_direction_to(Vector2i(0, 0), Vector2i(10, 10)), -1)


class TestDistance:
	extends GutTest

	func test_原点からの長さを計算できる():
		assert_eq(Hex.length(Vector2i(3, -7)), 7)

	func test_同じマスの距離は0():
		assert_eq(Hex.distance(Vector2i(2, -1), Vector2i(2, -1)), 0)

	func test_隣接マスの距離は1():
		for neighbor in Hex.neighbors(Vector2i(3, 4)):
			assert_eq(Hex.distance(Vector2i(3, 4), neighbor), 1)

	func test_離れたマスの距離を返す():
		assert_eq(Hex.distance(Vector2i(3, -7), Vector2i(0, 0)), 7)
		assert_eq(Hex.distance(Vector2i(0, 0), Vector2i(3, -1)), 3)
		assert_eq(Hex.distance(Vector2i(0, 0), Vector2i(2, 2)), 4)
		assert_eq(Hex.distance(Vector2i(-2, 1), Vector2i(1, -3)), 4)

	func test_半径0の範囲は中心のみ():
		assert_eq(Hex.within(Vector2i(2, 3), 0), [Vector2i(2, 3)])

	func test_半径2の範囲は距離2以内の19マス():
		var center := Vector2i(1, -2)

		var hexes := Hex.within(center, 2)

		assert_eq(hexes.size(), 19)
		for hex in hexes:
			assert_lte(Hex.distance(center, hex), 2)
		assert_has(hexes, center)
		assert_has(hexes, Vector2i(3, -2))


class TestRoundAndLine:
	extends GutTest

	func test_小数の座標をいちばん近いマスに丸められる():
		assert_eq(Hex.round(Vector2(5.0, -10.0)), Vector2i(5, -10))
		assert_eq(Hex.round(Vector2(1.1, -0.2)), Vector2i(1, 0))
		assert_eq(Hex.round(Vector2(0.2, 0.1)), Vector2i(0, 0))

	func test_同じマスへの直線はそのマスのみ():
		assert_eq(Hex.line(Vector2i(1, 1), Vector2i(1, 1)), [Vector2i(1, 1)])

	func test_軸に沿った直線を返す():
		assert_eq(
			Hex.line(Vector2i(0, 0), Vector2i(3, 0)),
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
		)

	func test_斜めの直線を返す():
		assert_eq(
			Hex.line(Vector2i(0, 0), Vector2i(1, -5)),
			[
				Vector2i(0, 0),
				Vector2i(0, -1),
				Vector2i(0, -2),
				Vector2i(1, -3),
				Vector2i(1, -4),
				Vector2i(1, -5),
			]
		)

	func test_斜めの直線は両端を含み隣接マスでつながる():
		var from := Vector2i(-2, 1)
		var to := Vector2i(2, -4)

		var line := Hex.line(from, to)

		assert_eq(line.size(), Hex.distance(from, to) + 1)
		assert_eq(line.front(), from)
		assert_eq(line.back(), to)
		for i in range(1, line.size()):
			assert_eq(Hex.distance(line[i - 1], line[i]), 1)


class TestPixel:
	extends GutTest

	func test_原点のマスは画面座標の原点になる():
		assert_eq(Hex.to_pixel(Vector2i(0, 0), 32.0), Vector2.ZERO)

	func test_q方向の隣は横に幅ひとつ分ずれる():
		var pixel := Hex.to_pixel(Vector2i(1, 0), 32.0)

		assert_almost_eq(pixel, Vector2(32.0 * sqrt(3.0), 0.0), Vector2(0.001, 0.001))

	func test_r方向の隣は半マス右の一段下にずれる():
		var pixel := Hex.to_pixel(Vector2i(0, 1), 32.0)

		assert_almost_eq(pixel, Vector2(16.0 * sqrt(3.0), 48.0), Vector2(0.001, 0.001))

	func test_マスの中心の画面座標は元のマスに戻る():
		for hex in Hex.within(Vector2i(0, 0), 3):
			assert_eq(Hex.from_pixel(Hex.to_pixel(hex, 32.0), 32.0), hex)

	func test_中心から少しずれた画面座標も同じマスになる():
		var center := Hex.to_pixel(Vector2i(2, -1), 32.0)

		assert_eq(Hex.from_pixel(center + Vector2(10.0, -12.0), 32.0), Vector2i(2, -1))
		assert_eq(Hex.from_pixel(center + Vector2(-20.0, 5.0), 32.0), Vector2i(2, -1))

	func test_画面上の位置は標準のレイアウトの位置と一致する():
		var layout := Layout.make_default()
		for hex in [Vector2i(0, 0), Vector2i(3, -1), Vector2i(-2, 5), Vector2i(-4, 2)]:
			var expected: Vector2 = Layout.hex_to_pixel(layout, hex)
			var actual := Hex.to_pixel(hex, layout.size.x)
			assert_almost_eq(actual, expected, Vector2(0.001, 0.001), str(hex))


class TestLayout:
	extends GutTest

	func test_make_defaultは標準レイアウトを返す():
		var layout = Layout.make_default()
		assert_eq(layout.size, Vector2(42.0, 42.0))
		assert_eq(layout.origin, Vector2.ZERO)

	func test_マスとピクセル座標を相互変換できる():
		var h := Vector2i(3, 4)

		var flat = Layout.new(Layout.layout_flat, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		assert_eq(Layout.pixel_to_hex_rounded(flat, Layout.hex_to_pixel(flat, h)), h)

		var pointy = Layout.new(Layout.layout_pointy, Vector2(10.0, 15.0), Vector2(35.0, 71.0))
		assert_eq(Layout.pixel_to_hex_rounded(pointy, Layout.hex_to_pixel(pointy, h)), h)

	func test_ピクセル座標から小数のマスの座標を求められる():
		var layout = Layout.make_default()
		var between = (
			(
				Layout.hex_to_pixel(layout, Vector2i(0, 0))
				+ Layout.hex_to_pixel(layout, Vector2i(1, 0))
			)
			* 0.5
		)

		var fractional: Vector2 = Layout.pixel_to_hex_fractional(layout, between)

		assert_almost_eq(fractional, Vector2(0.5, 0.0), Vector2(0.001, 0.001))
