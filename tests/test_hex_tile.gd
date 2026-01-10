class_name TestHexTile
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
