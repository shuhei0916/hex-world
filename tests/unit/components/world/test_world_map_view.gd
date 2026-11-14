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

	func test_set_hovered_chunkでそのタイルがホバー状態になる():
		view.setup(world)
		view.set_hovered_chunk(Hex.new(0, 0))
		assert_true(view.get_tile_hovered(Hex.new(0, 0)))

	func test_set_hovered_chunk切り替えで前のタイルのホバーが解除される():
		view.setup(world)
		view.set_hovered_chunk(Hex.new(0, 0))
		view.set_hovered_chunk(Hex.new(1, 0))
		assert_false(view.get_tile_hovered(Hex.new(0, 0)))

	func test_set_hovered_chunkにnullを渡すとホバーが解除される():
		view.setup(world)
		view.set_hovered_chunk(Hex.new(0, 0))
		view.set_hovered_chunk(null)
		assert_false(view.get_tile_hovered(Hex.new(0, 0)))

	func test_矢印は2つのタイルの中間の境目に配置される():
		view.setup(world)
		view.refresh_connections([[Hex.new(0, 0), Hex.new(1, 0)]])
		var pos0 = view.get_tile_position(Hex.new(0, 0))
		var pos1 = view.get_tile_position(Hex.new(1, 0))
		var expected_midpoint = (pos0 + pos1) / 2.0
		assert_eq(view.get_connection_arrow_position(0), expected_midpoint)


class TestPlanetMap:
	extends GutTest

	var view
	var world
	var planet: Planet

	func before_each():
		world = World.new()
		add_child_autofree(world)
		planet = Planet.new(2, 1)
		world.setup_planet(planet)
		view = WorldMapView.new()
		add_child_autofree(view)
		view.setup(world)

	func test_planetの全chunkのタイルが生成される():
		assert_eq(view.get_tile_count(), planet.get_chunk_hexes().size())

	func test_タイルはそのchunkのバイオーム色で塗られる():
		for hex in planet.get_chunk_hexes():
			assert_eq(view.get_tile_color(hex), planet.get_biome(hex).map_color, str(hex))

	func test_ホバー中のchunkのバイオーム名と資源名が表示される():
		var hex = Hex.new(1, 0)
		view.set_hovered_chunk(hex)
		var biome = planet.get_biome(hex)
		var text = view.get_hover_info_text()
		assert_string_contains(text, biome.display_name)
		assert_string_contains(text, ItemDB.get_item(biome.resource_type).display_name)

	func test_ホバー解除で情報表示が消える():
		view.set_hovered_chunk(Hex.new(1, 0))
		view.set_hovered_chunk(null)
		assert_eq(view.get_hover_info_text(), "")

	func test_再setupしても情報表示は1つだけ():
		view.setup(world)
		view.set_hovered_chunk(Hex.new(1, 0))
		assert_ne(view.get_hover_info_text(), "")
		assert_eq(view.get_tile_count(), planet.get_chunk_hexes().size())


class TestTileMatchesChunkSize:
	extends GutTest

	## ワールドマップのタイルは、ローカル画面の chunk と同じ縮尺の大きさにし、溝も同じ割合で見せる
	## （ズームでローカル画面とワールドマップを行き来しても大きさが変わらない）

	var view
	var world
	var saved_gap_steps

	func before_each():
		saved_gap_steps = World.gap_steps
		world = World.new()
		add_child_autofree(world)
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		world.set_active_chunk(Hex.new(0, 0))
		view = WorldMapView.new()
		add_child_autofree(view)

	func after_each():
		World.gap_steps = saved_gap_steps

	func test_タイルの大きさと間隔の比はchunkの大きさと間隔の比と同じ():
		view.setup(world)
		var map_ratio = view.get_tile_inradius(Hex.new(1, 0)) / view.get_tile_spacing()
		var local_ratio = world.get_chunk_inradius() / world.get_chunk_spacing()
		assert_almost_eq(map_ratio, local_ratio, 0.0001)

	func test_溝を広げるとタイルが小さくなる():
		World.gap_steps = 1
		view.setup(world)
		var narrow = view.get_tile_inradius(Hex.new(0, 0))
		World.gap_steps = 3
		view.setup(world)
		assert_lt(view.get_tile_inradius(Hex.new(0, 0)), narrow)
