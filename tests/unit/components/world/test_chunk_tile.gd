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
