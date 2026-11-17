extends GutTest

## 設置物の本体。占めるマスを合わせた1つの形を、マスの縁より少し内側に縮めて描く。
## 縮めたすき間から下の地面（床や鉱床）がのぞき、「マスの上に置かれた物」と分かる。

var body: PieceBody


func before_each():
	body = PieceBody.new()
	add_child_autofree(body)


func test_塗る色は渡した色():
	body.setup([Vector2i(0, 0)], Color.RED)

	assert_eq(body.get_fill_color(), Color.RED)


func test_1マスの本体はマスより内側に縮んだ六角形():
	var layout := Layout.make_default()
	body.setup([Vector2i(0, 0)], Color.RED)

	var outline := body.get_outline()

	assert_eq(outline.size(), 6)
	for point in outline:
		assert_almost_eq(point.length(), layout.size.x - PieceBody.INSET / cos(PI / 6), 0.01)


func test_複数マスの本体は1つの形で_どのマスの中心も含む():
	var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	body.setup(hexes, Color.RED)

	var outline := body.get_outline()

	assert_eq(outline.size(), 12)
	for hex in hexes:
		var center := Layout.hex_to_pixel(Layout.make_default(), hex)
		assert_true(Geometry2D.is_point_in_polygon(center, outline))


func test_本体はマスの縁から離れている():
	var layout := Layout.make_default()
	var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	body.setup(hexes, Color.RED)

	var union := HexShape.union_outline(layout, hexes)
	for point in body.get_outline():
		assert_true(Geometry2D.is_point_in_polygon(point, union))
		var nearest := INF
		for i in range(union.size()):
			var on_edge := Geometry2D.get_closest_point_to_segment(
				point, union[i], union[(i + 1) % union.size()]
			)
			nearest = minf(nearest, point.distance_to(on_edge))
		# 凹んだ角では角の点から斜めに離れるので、INSET より少し遠くなる
		assert_gte(nearest, PieceBody.INSET - 0.01)
