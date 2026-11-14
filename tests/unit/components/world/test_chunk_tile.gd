extends GutTest

const ChunkTile = preload("res://scenes/components/world/chunk_tile.gd")


class TestChunkTile:
	extends GutTest

	var tile

	func before_each():
		tile = ChunkTile.new()
		add_child_autofree(tile)

	func test_setup後にchunk_hexが設定される():
		tile.setup(Hex.new(1, 0))
		assert_true(Hex.equals(tile.chunk_hex, Hex.new(1, 0)))

	func test_デフォルトでis_activeはfalse():
		tile.setup(Hex.new(0, 0))
		assert_false(tile.is_active)

	func test_set_active_trueでis_activeがtrueになる():
		tile.setup(Hex.new(0, 0))
		tile.set_active(true)
		assert_true(tile.is_active)

	func test_set_active_falseでis_activeがfalseに戻る():
		tile.setup(Hex.new(0, 0))
		tile.set_active(true)
		tile.set_active(false)
		assert_false(tile.is_active)

	func test_アクティブかつホバー中はアクティブ色が優先される():
		tile.setup(Hex.new(0, 0))
		tile.set_active(true)
		var active_color = tile.get_current_color()
		tile.set_hovered(true)
		assert_eq(tile.get_current_color(), active_color)

	func test_基本色を指定するとその色で塗られる():
		tile.setup(Hex.new(0, 0), Color.RED)
		assert_eq(tile.get_current_color(), Color.RED)

	func test_基本色を省略すると既定色で塗られる():
		tile.setup(Hex.new(0, 0))
		assert_eq(tile.get_current_color(), ChunkTile.NORMAL_COLOR)

	func test_ホバー中は基本色より明るくなる():
		tile.setup(Hex.new(0, 0), Color("#404040"))
		tile.set_hovered(true)
		assert_gt(tile.get_current_color().v, Color("#404040").v)

	func test_アクティブ時はホバー時よりさらに明るくなる():
		tile.setup(Hex.new(0, 0), Color("#404040"))
		tile.set_hovered(true)
		var hovered = tile.get_current_color()
		tile.set_hovered(false)
		tile.set_active(true)
		assert_gt(tile.get_current_color().v, hovered.v)


class TestChunkTileSprite:
	extends GutTest

	const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")

	var tile

	func before_each():
		tile = ChunkTile.new()
		add_child_autofree(tile)
		tile.setup(Hex.new(0, 0), Color("#404040"))

	func _local_sprite() -> Sprite2D:
		var hex_tile = HEX_TILE_SCENE.instantiate()
		autofree(hex_tile)
		return hex_tile.get_node("Sprite2D")

	func test_ローカルの床のマスと同じデザインのflat_top版の画像で描く():
		assert_eq(tile.get_sprite().texture, HexTile.FLAT_TEXTURE)

	func test_床のマスの画像はHexTileの画像である():
		assert_eq(_local_sprite().texture, HexTile.TEXTURE)

	func test_画像は回さない_回すと上からの陰影が横向きになる():
		assert_eq(tile.get_sprite().rotation, 0.0)

	func test_マスに対する画像の大きさの比はローカルの床と同じ():
		var local_ratio = _local_sprite().scale.x / Layout.make_default().size.x
		assert_almost_eq(tile.get_sprite().scale.x / ChunkTile.TILE_SIZE, local_ratio, 0.0001)

	func test_画像は今の色で塗られる():
		tile.set_hovered(true)
		assert_eq(tile.get_sprite().modulate, tile.get_current_color())
		tile.set_active(true)
		assert_eq(tile.get_sprite().modulate, tile.get_current_color())
