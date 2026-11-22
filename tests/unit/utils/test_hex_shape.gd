extends GutTest

## マスの形（角のとがった六角形）。ローカル画面・ワールドマップ・戦闘のどれも同じ形で描く。


func test_頂点は6つで_どれも中心から同じ距離にある():
	var corners := HexShape.corners(Vector2(5, 7), 10.0, true)

	assert_eq(corners.size(), 6)
	for corner in corners:
		assert_almost_eq(corner.distance_to(Vector2(5, 7)), 10.0, 0.001)


func test_頂点が上を向く形は真上に頂点がある():
	var corners := HexShape.corners(Vector2.ZERO, 10.0, true)

	assert_true(_has_point(corners, Vector2(0, -10)))
	assert_false(_has_point(corners, Vector2(10, 0)))


func test_辺が上を向く形は真横に頂点がある():
	var corners := HexShape.corners(Vector2.ZERO, 10.0, false)

	assert_true(_has_point(corners, Vector2(10, 0)))
	assert_false(_has_point(corners, Vector2(0, -10)))


func test_輪郭は最初の頂点に戻って閉じる():
	var outline := HexShape.outline(Vector2.ZERO, 10.0, true)

	assert_eq(outline.size(), 7)
	assert_eq(outline[6], outline[0])


func test_1マスの外周はそのマスの6つの頂点():
	var layout := Layout.make_default()

	var outline := HexShape.union_outline(layout, [Vector2i(0, 0)])

	assert_eq(outline.size(), 6)
	for corner in HexShape.corners(Vector2.ZERO, layout.size.x, true):
		assert_true(_has_point(outline, corner))


func test_隣り合う2マスの外周は共有する辺を除いた10頂点():
	var layout := Layout.make_default()

	var outline := HexShape.union_outline(layout, [Vector2i(0, 0), Vector2i(1, 0)])

	assert_eq(outline.size(), 10)


func test_三角に並んだ3マスの外周は12頂点で_中心は内側():
	var layout := Layout.make_default()
	var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]

	var outline := HexShape.union_outline(layout, hexes)

	assert_eq(outline.size(), 12)
	for hex in hexes:
		assert_true(Geometry2D.is_point_in_polygon(Layout.hex_to_pixel(layout, hex), outline))


func test_一列に並んだ3マスの外周は一続きの14頂点():
	var layout := Layout.make_default()
	var hexes: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]

	var outline := HexShape.union_outline(layout, hexes)

	assert_eq(outline.size(), 14)
	for i in range(outline.size()):
		var edge := outline[i].distance_to(outline[(i + 1) % outline.size()])
		assert_almost_eq(edge, layout.size.x, 0.01, "外周は辺を順にたどる")


func _has_point(points: PackedVector2Array, target: Vector2) -> bool:
	for point in points:
		if point.distance_to(target) < 0.001:
			return true
	return false
