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
