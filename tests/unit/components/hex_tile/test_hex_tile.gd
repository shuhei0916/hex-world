extends GutTest

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
var hex_tile: HexTile


func before_each():
	hex_tile = HexTileScene.instantiate()
	add_child_autofree(hex_tile)
	hex_tile.setup_hex(Vector2i(0, 0))


func test_床は戦闘の盤面と同じ色で塗る():
	assert_eq(hex_tile.get_fill_color(), HexStyle.FLOOR_COLOR)


func test_色を設定するとその色で塗る():
	hex_tile.set_color(Color.RED)

	assert_eq(hex_tile.get_fill_color(), Color.RED)


func test_色をリセットすると床の色に戻る():
	hex_tile.set_color(Color.RED)

	hex_tile.reset_color()

	assert_eq(hex_tile.get_fill_color(), HexStyle.FLOOR_COLOR)


func test_透明度を設定できる():
	hex_tile.set_color(Color.RED)

	hex_tile.set_transparency(0.5)

	assert_eq(hex_tile.get_color(), Color(1, 0, 0, 0.5))
	assert_eq(hex_tile.get_fill_color(), Color(1, 0, 0, 0.5))


func test_ハイライト中はハイライトの色で塗る():
	hex_tile.set_color(Color.RED)

	hex_tile.set_highlight(true)

	assert_eq(hex_tile.get_fill_color(), hex_tile.highlight_color)
	assert_eq(hex_tile.get_color(), Color.RED, "元の色は覚えている")


func test_画像を使わずに描く():
	assert_null(hex_tile.get_node_or_null("Sprite2D"))


func test_マスはすき間なく並ぶ大きさで描く():
	assert_eq(HexTile.visual_circumradius(), Layout.make_default().size.x)


func test_頂点が上を向く六角形で描く():
	var outline := hex_tile.get_outline()

	assert_eq(outline, HexShape.outline(Vector2.ZERO, HexTile.visual_circumradius(), true))
