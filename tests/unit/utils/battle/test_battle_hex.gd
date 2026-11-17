extends GutTest


func test_原点に隣接する6マスを返す():
	var neighbors := BattleHex.neighbors(Vector2i(0, 0))

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


func test_同じマスの距離は0():
	assert_eq(BattleHex.distance(Vector2i(2, -1), Vector2i(2, -1)), 0)


func test_隣接マスの距離は1():
	for neighbor in BattleHex.neighbors(Vector2i(3, 4)):
		assert_eq(BattleHex.distance(Vector2i(3, 4), neighbor), 1)


func test_離れたマスの距離を返す():
	assert_eq(BattleHex.distance(Vector2i(0, 0), Vector2i(3, -1)), 3)
	assert_eq(BattleHex.distance(Vector2i(0, 0), Vector2i(2, 2)), 4)
	assert_eq(BattleHex.distance(Vector2i(-2, 1), Vector2i(1, -3)), 4)


func test_半径0の範囲は中心のみ():
	assert_eq(BattleHex.within(Vector2i(2, 3), 0), [Vector2i(2, 3)])


func test_半径2の範囲は距離2以内の19マス():
	var center := Vector2i(1, -2)

	var hexes := BattleHex.within(center, 2)

	assert_eq(hexes.size(), 19)
	for hex in hexes:
		assert_lte(BattleHex.distance(center, hex), 2)
	assert_has(hexes, center)
	assert_has(hexes, Vector2i(3, -2))


func test_同じマスへの直線はそのマスのみ():
	assert_eq(BattleHex.line(Vector2i(1, 1), Vector2i(1, 1)), [Vector2i(1, 1)])


func test_軸に沿った直線を返す():
	assert_eq(
		BattleHex.line(Vector2i(0, 0), Vector2i(3, 0)),
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	)


func test_斜めの直線は両端を含み隣接マスでつながる():
	var from := Vector2i(-2, 1)
	var to := Vector2i(2, -4)

	var line := BattleHex.line(from, to)

	assert_eq(line.size(), BattleHex.distance(from, to) + 1)
	assert_eq(line.front(), from)
	assert_eq(line.back(), to)
	for i in range(1, line.size()):
		assert_eq(BattleHex.distance(line[i - 1], line[i]), 1)


func test_原点のヘックスは画面座標の原点になる():
	assert_eq(BattleHex.to_pixel(Vector2i(0, 0), 32.0), Vector2.ZERO)


func test_q方向の隣は横に幅ひとつ分ずれる():
	var pixel := BattleHex.to_pixel(Vector2i(1, 0), 32.0)

	assert_almost_eq(pixel, Vector2(32.0 * sqrt(3.0), 0.0), Vector2(0.001, 0.001))


func test_r方向の隣は半マス右の一段下にずれる():
	var pixel := BattleHex.to_pixel(Vector2i(0, 1), 32.0)

	assert_almost_eq(pixel, Vector2(16.0 * sqrt(3.0), 48.0), Vector2(0.001, 0.001))


func test_ヘックス中心の画面座標は元のヘックスに戻る():
	for hex in BattleHex.within(Vector2i(0, 0), 3):
		assert_eq(BattleHex.from_pixel(BattleHex.to_pixel(hex, 32.0), 32.0), hex)


func test_中心から少しずれた画面座標も同じヘックスになる():
	var center := BattleHex.to_pixel(Vector2i(2, -1), 32.0)

	assert_eq(BattleHex.from_pixel(center + Vector2(10.0, -12.0), 32.0), Vector2i(2, -1))
	assert_eq(BattleHex.from_pixel(center + Vector2(-20.0, 5.0), 32.0), Vector2i(2, -1))


func test_工場側のHexと行き来できる():
	assert_eq(BattleHex.from_hex(Hex.new(2, -3)), Vector2i(2, -3))
	assert_true(Hex.equals(BattleHex.to_hex(Vector2i(2, -3)), Hex.new(2, -3)))


func test_画面上の位置は工場側のマスの位置と一致する():
	var layout := Layout.make_default()
	for hex in [Hex.new(0, 0), Hex.new(3, -1), Hex.new(-2, 5), Hex.new(-4, 2)]:
		var expected: Vector2 = Layout.hex_to_pixel(layout, hex)
		var actual := BattleHex.to_pixel(BattleHex.from_hex(hex), layout.size.x)
		assert_almost_eq(actual, expected, Vector2(0.001, 0.001), str(hex))
