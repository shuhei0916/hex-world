extends GutTest

const ChunkTile = preload("res://scenes/components/world/chunk_tile.gd")


class TestChunkTile:
	extends GutTest

	var tile

	func before_each():
		tile = ChunkTile.new()
		add_child_autofree(tile)

	func test_setup後にchunk_hexが設定される():
		tile.setup(Vector2i(1, 0))
		assert_true(tile.chunk_hex == Vector2i(1, 0))

	func test_デフォルトでis_activeはfalse():
		tile.setup(Vector2i(0, 0))
		assert_false(tile.is_active)

	func test_set_active_trueでis_activeがtrueになる():
		tile.setup(Vector2i(0, 0))
		tile.set_active(true)
		assert_true(tile.is_active)

	func test_set_active_falseでis_activeがfalseに戻る():
		tile.setup(Vector2i(0, 0))
		tile.set_active(true)
		tile.set_active(false)
		assert_false(tile.is_active)

	func test_基本色を指定するとその色で塗られる():
		tile.setup(Vector2i(0, 0), Color.RED)
		assert_eq(tile.get_current_color(), Color.RED)

	func test_基本色を省略すると既定色で塗られる():
		tile.setup(Vector2i(0, 0))
		assert_eq(tile.get_current_color(), ChunkTile.NORMAL_COLOR)


class TestChunkTileMarker:
	extends GutTest

	## 今いる chunk とホバー中の chunk は、塗りの色（バイオーム）を変えずに、
	## タイルの内側に一回り小さい六角形の輪を描いて示す

	var tile

	func before_each():
		ColorTheme.set_mode(ColorTheme.Mode.DARK)
		tile = ChunkTile.new()
		add_child_autofree(tile)
		tile.setup(Vector2i(0, 0), Color("#5a8c3a"))
		tile.set_inradius(70.0)

	func after_each():
		ColorTheme.set_mode(ColorTheme.Mode.DARK)

	func test_ふだんは輪を描かない():
		assert_true(tile.get_ring().is_empty())

	func test_今いるchunkでもホバー中でも塗りはバイオームの色のまま():
		tile.set_hovered(true)
		assert_eq(tile.get_fill_color(), Color("#5a8c3a"))
		tile.set_active(true)
		assert_eq(tile.get_fill_color(), Color("#5a8c3a"))

	func test_今いるchunkには印の色の輪を描く():
		tile.set_active(true)
		var ring: Dictionary = tile.get_ring()
		assert_eq(ring["color"], ColorTheme.color(&"map_marker"))
		assert_eq(ring["width"], ChunkTile.ACTIVE_RING_WIDTH)

	func test_輪は隣のタイルに覆われないよう_線の太さも含めてタイルの内側に収める():
		tile.set_active(true)
		var ring: Dictionary = tile.get_ring()
		var limit: float = tile.get_inradius() - HexStyle.BORDER_WIDTH
		for point in ring["points"]:
			# 頂点ではなく辺までの距離で比べる（辺が上を向く六角形の、辺の中点の方向の成分）
			for i in 6:
				var normal := Vector2.from_angle(deg_to_rad(30.0 + 60.0 * i))
				assert_lt(point.dot(normal) + ring["width"] * 0.5, limit + 0.01)

	func test_輪は一周つながっている():
		tile.set_active(true)
		var points: PackedVector2Array = tile.get_ring()["points"]
		assert_eq(points[0], points[points.size() - 1])

	func test_ホバー中は今いるchunkより細く淡い輪を描く():
		tile.set_hovered(true)
		var ring: Dictionary = tile.get_ring()
		assert_lt(ring["width"], ChunkTile.ACTIVE_RING_WIDTH)
		assert_lt(ring["color"].a, ColorTheme.color(&"map_marker").a)

	func test_今いるchunkにホバーしても今いるchunkの輪のまま():
		tile.set_active(true)
		tile.set_hovered(true)
		assert_eq(tile.get_ring()["width"], ChunkTile.ACTIVE_RING_WIDTH)

	func test_輪の色は配色に従う():
		tile.set_active(true)
		ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
		assert_eq(tile.get_ring()["color"], ColorTheme.LIGHT[&"map_marker"])


class TestChunkTileShape:
	extends GutTest

	var tile

	func before_each():
		tile = ChunkTile.new()
		add_child_autofree(tile)
		tile.setup(Vector2i(0, 0), Color("#404040"))

	func test_画像を使わずに描く():
		assert_null(tile.get_node_or_null("Sprite2D"))

	func test_中心から辺までの距離を指定できる():
		tile.set_inradius(50.0)
		assert_almost_eq(tile.get_inradius(), 50.0, 0.001)

	func test_辺が上を向く六角形で_辺がその距離に来る大きさで描く():
		tile.set_inradius(50.0)

		var circumradius = 50.0 * 2.0 / sqrt(3.0)
		assert_eq(tile.get_outline(), HexShape.outline(Vector2.ZERO, circumradius, false))
