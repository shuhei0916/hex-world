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


func _has_point(points: PackedVector2Array, target: Vector2) -> bool:
	for point in points:
		if point.distance_to(target) < 0.001:
			return true
	return false
