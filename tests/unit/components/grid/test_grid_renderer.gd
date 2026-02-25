# gdlint:disable=constant-name
extends GutTest

const GridRenderer = preload("res://scenes/components/grid/grid_renderer.gd")


class TestFindHexTile:
	extends GutTest

	var renderer
	var layout: Layout

	func before_each():
		layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2(0.0, 0.0))
		renderer = GridRenderer.new()
		renderer.setup(layout)
		add_child_autofree(renderer)

	func test_draw_grid後にfind_hex_tileが正しいタイルを返す():
		var hex = Hex.new(0, 0)
		var hexes: Array[Hex] = [hex]
		renderer.draw_grid(hexes)
		assert_not_null(renderer.find_hex_tile(hex))

	func test_登録されていないhexはnullを返す():
		var hexes: Array[Hex] = [Hex.new(0, 0)]
		renderer.draw_grid(hexes)
		assert_null(renderer.find_hex_tile(Hex.new(9, 9)))

	func test_draw_grid後のタイル数がhex数と一致する():
		var hexes: Array[Hex] = [Hex.new(0, 0), Hex.new(1, 0), Hex.new(0, 1)]
		renderer.draw_grid(hexes)
		assert_eq(renderer.get_child_count(), 3)


class TestTileColor:
	extends GutTest

	var renderer
	var layout: Layout

	func before_each():
		layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2(0.0, 0.0))
		renderer = GridRenderer.new()
		renderer.setup(layout)
		add_child_autofree(renderer)
		var hexes: Array[Hex] = [Hex.new(0, 0)]
		renderer.draw_grid(hexes)

	func test_set_tile_colorでタイルの色が変わる():
		var hex = Hex.new(0, 0)
		renderer.set_tile_color(hex, Color.RED)
		var tile = renderer.find_hex_tile(hex)
		assert_eq(tile.get_color(), Color.RED)

	func test_reset_tile_colorでデフォルト色に戻る():
		var hex = Hex.new(0, 0)
		renderer.set_tile_color(hex, Color.RED)
		renderer.reset_tile_color(hex)
		var tile = renderer.find_hex_tile(hex)
		assert_eq(tile.get_color(), tile.normal_color)

	func test_存在しないhexへのset_tile_colorはエラーなく動作する():
		renderer.set_tile_color(Hex.new(9, 9), Color.RED)
		assert_true(true, "エラーが発生しなければOK")
