extends GutTest


class TestFindHexTile:
	extends GutTest

	var renderer
	var layout: Layout

	func before_each():
		layout = Layout.make_default()
		renderer = GridRenderer.new()
		renderer.setup(layout)
		add_child_autofree(renderer)

	func test_draw_grid後にfind_hex_tileが正しいタイルを返す():
		var hex = Vector2i(0, 0)
		var hexes: Array[Vector2i] = [hex]
		renderer.draw_grid(hexes)
		assert_not_null(renderer.find_hex_tile(hex))

	func test_登録されていないhexはnullを返す():
		var hexes: Array[Vector2i] = [Vector2i(0, 0)]
		renderer.draw_grid(hexes)
		assert_null(renderer.find_hex_tile(Vector2i(9, 9)))

	func test_draw_grid後のタイル数がhex数と一致する():
		var hexes: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
		renderer.draw_grid(hexes)
		assert_eq(renderer.get_child_count(), 3)
