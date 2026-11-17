extends GutTest

## 設置物の本体（shapez の建物のような見た目）。占めるマスを合わせた1つの形を、
## マスの縁より少し内側に縮め、角を丸めて、種類ごとの色で塗り濃い線で縁取って描く。
## 中央には作っている品物などのアイコンを出す。

const ICON = preload("res://assets/items/iron_ingot.svg")

var body: PieceBody


func before_each():
	body = PieceBody.new()
	add_child_autofree(body)


func test_塗る色は渡した種類ごとの色():
	body.setup([Vector2i(0, 0)], Color.RED)

	assert_eq(body.get_fill_color(), Color.RED)


func test_1マスの本体はマスの内側に収まり_縁から離れている():
	var hexes: Array[Vector2i] = [Vector2i(0, 0)]
	body.setup(hexes, Color.RED)

	_assert_inside_with_margin(body.get_outline(), hexes)


func test_角は丸めてあり_とがった角まで届かない():
	var layout := Layout.make_default()
	body.setup([Vector2i(0, 0)], Color.RED)

	var sharp_corner := layout.size.x - PieceBody.INSET / cos(PI / 6)
	var farthest := 0.0
	for point in body.get_outline():
		farthest = maxf(farthest, point.length())
	assert_lt(farthest, sharp_corner - 1.0)
	assert_gt(body.get_outline().size(), 6, "丸めた角は複数の点でなめらかに描く")


func test_複数マスの本体は1つの形で_どのマスの中心も含み_縁から離れている():
	var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	body.setup(hexes, Color.RED)

	var outline := body.get_outline()
	for hex in hexes:
		var center := Layout.hex_to_pixel(Layout.make_default(), hex)
		assert_true(Geometry2D.is_point_in_polygon(center, outline))
	_assert_inside_with_margin(outline, hexes)


func test_アイコンを渡すと中央に描く():
	body.setup([Vector2i(0, 0)], Color.RED)
	body.set_icon(ICON)

	assert_eq(body.get_icon(), ICON)
	assert_eq(body.get_icon_center(), Vector2.ZERO)


func test_アイコンは形の中心に最も近いマスの中央に置く():
	# 一列の3マスなら真ん中のマス
	var hexes: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]
	body.setup(hexes, Color.RED)

	assert_eq(body.get_icon_center(), Vector2.ZERO)


func test_アイコンは無しにもできる():
	body.setup([Vector2i(0, 0)], Color.RED)
	body.set_icon(ICON)
	body.set_icon(null)

	assert_null(body.get_icon())


func _assert_inside_with_margin(outline: PackedVector2Array, hexes: Array[Vector2i]) -> void:
	var union := HexShape.union_outline(Layout.make_default(), hexes)
	for point in outline:
		assert_true(Geometry2D.is_point_in_polygon(point, union))
		var nearest := INF
		for i in range(union.size()):
			var on_edge := Geometry2D.get_closest_point_to_segment(
				point, union[i], union[(i + 1) % union.size()]
			)
			nearest = minf(nearest, point.distance_to(on_edge))
		assert_gte(nearest, PieceBody.INSET - 0.05)
