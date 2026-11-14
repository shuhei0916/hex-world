extends GutTest

const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
var hex_tile: HexTile


func before_each():
	hex_tile = HexTileScene.instantiate()
	add_child_autofree(hex_tile)


func test_透明度を設定できる():
	var initial_color = Color.RED
	hex_tile.set_color(initial_color)

	# 透明度を0.5に設定
	hex_tile.set_transparency(0.5)

	# 期待される色：RGBはそのまま、Alphaが0.5
	var expected_color = Color(initial_color.r, initial_color.g, initial_color.b, 0.5)

	# 現在の色を取得して確認
	assert_eq(hex_tile.get_color(), expected_color, "Alpha should be 0.5")

	# スプライトのmodulateも確認
	var sprite = hex_tile.get_node_or_null("Sprite2D")
	if sprite:
		assert_eq(sprite.modulate, expected_color, "Sprite modulate should reflect transparency")


class TestTileTexture:
	extends GutTest

	# マスの色は modulate だけで決まるよう、画像は陰影の無い白一色にする
	func _assert_plain_white(texture: Texture2D) -> void:
		var image = texture.get_image()
		var center = Vector2i(image.get_width() / 2, image.get_height() / 2)
		for y in [center.y - 80, center.y, center.y + 80]:
			var pixel = image.get_pixel(center.x, y)
			assert_almost_eq(pixel.v, 1.0, 0.01, "y=%d が白" % y)

	func test_床の画像は陰影の無い白一色():
		_assert_plain_white(HexTile.TEXTURE)

	func test_ワールドマップの画像も陰影の無い白一色():
		_assert_plain_white(HexTile.FLAT_TEXTURE)
