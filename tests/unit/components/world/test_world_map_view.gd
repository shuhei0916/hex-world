extends GutTest

const WorldMapView = preload("res://scenes/components/world/world_map_view.gd")
const World = preload("res://scenes/components/world/world.gd")


class TestWorldMapView:
	extends GutTest

	var view
	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		view = WorldMapView.new()
		add_child_autofree(view)

	func test_setupでチャンク数と同数のChunkTileが生成される():
		view.setup(world)
		assert_eq(view.get_tile_count(), 2)

	func test_異なるhexのタイルは異なる位置に配置される():
		view.setup(world)
		var pos0 = view.get_tile_position(Hex.new(0, 0))
		var pos1 = view.get_tile_position(Hex.new(1, 0))
		assert_ne(pos0, pos1)

	func test_set_active_chunkでそのタイルがアクティブになる():
		view.setup(world)
		view.set_active_chunk(Hex.new(0, 0))
		assert_true(view.get_tile_active(Hex.new(0, 0)))

	func test_set_active_chunk切り替えで前のタイルが非アクティブになる():
		view.setup(world)
		view.set_active_chunk(Hex.new(0, 0))
		view.set_active_chunk(Hex.new(1, 0))
		assert_false(view.get_tile_active(Hex.new(0, 0)))

	func test_タイル中心位置を渡すと対応するhexを返す():
		view.setup(world)
		var center = view.get_tile_position(Hex.new(0, 0))
		assert_true(Hex.equals(view.chunk_at_local_pos(center), Hex.new(0, 0)))

	func test_タイルが存在しない位置ではnullを返す():
		view.setup(world)
		assert_null(view.chunk_at_local_pos(Vector2(9999, 9999)))

	func test_refresh_connectionsで接続ペア数分の矢印が境目に生成される():
		view.setup(world)
		view.refresh_connections([[Hex.new(0, 0), Hex.new(1, 0)]])
		assert_eq(view.get_connection_arrow_count(), 1)

	func test_接続ペアがなければ矢印は生成されない():
		view.setup(world)
		view.refresh_connections([])
		assert_eq(view.get_connection_arrow_count(), 0)

	func test_再表示のたびに前回分の矢印がクリアされる():
		view.setup(world)
		view.refresh_connections([[Hex.new(0, 0), Hex.new(1, 0)]])
		view.refresh_connections([[Hex.new(0, 0), Hex.new(1, 0)]])
		assert_eq(view.get_connection_arrow_count(), 1)

	func test_矢印は2つのタイルの中間の境目に配置される():
		view.setup(world)
		view.refresh_connections([[Hex.new(0, 0), Hex.new(1, 0)]])
		var pos0 = view.get_tile_position(Hex.new(0, 0))
		var pos1 = view.get_tile_position(Hex.new(1, 0))
		var expected_midpoint = (pos0 + pos1) / 2.0
		assert_eq(view.get_connection_arrow_position(0), expected_midpoint)
