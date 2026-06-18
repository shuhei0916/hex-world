extends GutTest

const World = preload("res://scenes/components/world/world.gd")


class TestWorldChunkManagement:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_create_chunkで指定hexにChunkが生成される():
		var chunk = world.create_chunk(Hex.new(0, 0))
		assert_not_null(chunk)

	func test_get_chunkで作成済みChunkを取得できる():
		world.create_chunk(Hex.new(0, 0))
		assert_not_null(world.get_chunk(Hex.new(0, 0)))

	func test_get_chunkで存在しないhexはnullを返す():
		assert_null(world.get_chunk(Hex.new(1, 0)))

	func test_同じhexへのcreate_chunkは同一Chunkを返す():
		var a = world.create_chunk(Hex.new(0, 0))
		var b = world.create_chunk(Hex.new(0, 0))
		assert_eq(a, b)

	func test_create_chunkした直後のChunkはデフォルト非表示():
		var chunk = world.create_chunk(Hex.new(0, 0))
		assert_false(chunk.visible)

	func test_create_chunkしたhexはget_chunk_hexesで取得できる():
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		var hexes = world.get_chunk_hexes()
		assert_eq(hexes.size(), 2)


class TestWorldActiveChunk:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_初期状態ではget_active_chunkはnullを返す():
		assert_null(world.get_active_chunk())

	func test_set_active_chunkでそのChunkが表示される():
		world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))
		assert_true(world.get_chunk(Hex.new(0, 0)).visible)

	func test_set_active_chunkで前のアクティブChunkは非表示になる():
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		world.set_active_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(1, 0))
		assert_false(world.get_chunk(Hex.new(0, 0)).visible)

	func test_get_active_chunkはアクティブなChunkを返す():
		var chunk = world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))
		assert_eq(world.get_active_chunk(), chunk)
