# gdlint:disable=max-public-methods
# gdlint:disable=duplicated-load
extends GutTest

const World = preload("res://scenes/components/world/world.gd")


class TestBridgeWiring:
	extends GutTest

	## 橋は chunk の辺に置き、溝の向こうの隣の chunk の向かいのマス（mirror_hex）にある
	## コンベアや施設へアイテムを渡す。受け取り専用の施設は要らない。

	const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")
	const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
	const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Vector2i(0, 0))
		chunk_b = world.create_chunk(Vector2i(1, 0))  # 東隣
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)

	# SE(5)の辺の橋と、その向かいのマス（worldmap 上の東隣(1,0)の chunk の中）
	func _bridge_hex() -> Vector2i:
		return Vector2i(1, 1)

	func _landing_hex() -> Vector2i:
		return Vector2i(-1, -1)

	func _bridge() -> Piece:
		return chunk_a.get_piece_at_hex(_bridge_hex())

	func test_向かいのマスにコンベアを後から置くと橋がつながる():
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		chunk_b.place_piece(CONVEYOR, _landing_hex())
		assert_eq(_bridge().get_connected_pieces(), [chunk_b.get_piece_at_hex(_landing_hex())])

	func test_向かいのマスに先に置いてあっても橋を置いたときにつながる():
		chunk_b.place_piece(CONVEYOR, _landing_hex())
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		assert_eq(_bridge().get_connected_pieces(), [chunk_b.get_piece_at_hex(_landing_hex())])

	func test_施設にも直接渡せる():
		chunk_b.place_piece(CHEST_IN, _landing_hex())
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		assert_eq(_bridge().get_connected_pieces(), [chunk_b.get_piece_at_hex(_landing_hex())])

	func test_向かいのマスが空ならつながらない():
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		assert_eq(_bridge().get_connected_pieces(), [])

	func test_向かいからずれた位置のコンベアにはつながらない():
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		chunk_b.place_piece(CONVEYOR, Vector2i(-2, 0))
		assert_eq(_bridge().get_connected_pieces(), [])

	func test_向かい合う橋どうしはつながらない():
		# つなぐと、アイテムが溝の上を行ったり来たりする
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		chunk_b.place_piece(BRIDGE_SCENE, _landing_hex())
		assert_eq(_bridge().get_connected_pieces(), [])
		assert_eq(chunk_b.get_piece_at_hex(_landing_hex()).get_connected_pieces(), [])

	func test_向かいのマスのコンベアを撤去すると解除される():
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		chunk_b.place_piece(CONVEYOR, _landing_hex())
		chunk_b.remove_piece_at(_landing_hex())
		assert_eq(_bridge().get_connected_pieces(), [])

	func test_南東のchunkへも辺の対応位置でつながる():
		var chunk_c = world.create_chunk(Vector2i(0, 1))  # 南東隣
		chunk_c.create_hex_grid(2)
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(-1, 2))
		chunk_c.place_piece(CONVEYOR, Vector2i(1, -2))
		var bridge = chunk_a.get_piece_at_hex(Vector2i(-1, 2))
		assert_eq(bridge.get_connected_pieces(), [chunk_c.get_piece_at_hex(Vector2i(1, -2))])

	func test_点対称位置ではなく辺内の対応位置につながる():
		# chunk(0,0)のhex(4,1,-5)(SEの辺、q=radius寄りの端)は、
		# 単純な原点対称(-4,-1,5)ではなく、辺内で対応する位置(-1,-4,5)につながる。
		chunk_a.grid_radius = 5
		chunk_b.grid_radius = 5
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(4, 1))
		chunk_b.place_piece(CONVEYOR, Vector2i(-1, -4))
		var bridge = chunk_a.get_piece_at_hex(Vector2i(4, 1))
		assert_eq(bridge.get_connected_pieces(), [chunk_b.get_piece_at_hex(Vector2i(-1, -4))])

	func test_表示していないchunkのコンベアへもアイテムが届く():
		world.set_active_chunk(Vector2i(0, 0))
		chunk_a.place_piece(BRIDGE_SCENE, _bridge_hex())
		chunk_b.place_piece(CONVEYOR, _landing_hex())
		_bridge().add_item("iron_ore", 1)
		_bridge().tick(1.0)
		assert_eq(chunk_b.get_piece_at_hex(_landing_hex()).get_item_count("iron_ore"), 1)


class TestBridgeLandingHints:
	extends GutTest

	## 橋の向かいのマスが空いているとき、そこを「受け取りを置く場所」として光らせる

	const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")
	const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Vector2i(0, 0))
		chunk_b = world.create_chunk(Vector2i(1, 0))  # 東隣
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)

	func test_隣のchunkの橋の向かいのマスが着地点の候補になる():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		var hints = world.get_bridge_landing_hexes(Vector2i(1, 0))
		assert_eq(hints, [Vector2i(-1, -1)])

	func test_隣に描いているchunkでも着地点が光る():
		world.set_active_chunk(Vector2i(0, 0))
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		assert_true(chunk_b.find_hex_tile(Vector2i(-1, -1)).is_highlighted)

	func test_アクティブなchunkの着地点も光る():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		world.set_active_chunk(Vector2i(1, 0))
		assert_true(chunk_b.find_hex_tile(Vector2i(-1, -1)).is_highlighted)

	func test_橋を撤去すると着地点の光が消える():
		world.set_active_chunk(Vector2i(0, 0))
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		chunk_a.remove_piece_at(Vector2i(1, 1))
		assert_false(chunk_b.find_hex_tile(Vector2i(-1, -1)).is_highlighted)

	func test_着地点に何か置くと候補から外れ_光も消える():
		world.set_active_chunk(Vector2i(0, 0))
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		chunk_b.place_piece(CONVEYOR, Vector2i(-1, -1))
		assert_eq(world.get_bridge_landing_hexes(Vector2i(1, 0)), [])
		assert_false(chunk_b.find_hex_tile(Vector2i(-1, -1)).is_highlighted)


class TestBridgeSpans:
	extends GutTest

	## 溝の上に描く橋の帯。画面上の始点（橋のマス）と終点（向かいのマス）、つながっているか

	const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")
	const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Vector2i(0, 0))
		chunk_b = world.create_chunk(Vector2i(1, 0))
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)
		world.set_active_chunk(Vector2i(0, 0))

	func _screen(chunk: Chunk, hex: Vector2i) -> Vector2:
		return chunk.position + chunk.hex_to_pixel(hex)

	func test_橋のマスから向かいのマスまでの帯になる():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		var spans = world.get_bridge_spans()
		assert_eq(spans.size(), 1)
		assert_true(spans[0]["from"].is_equal_approx(_screen(chunk_a, Vector2i(1, 1))))
		assert_true(spans[0]["to"].is_equal_approx(_screen(chunk_b, Vector2i(-1, -1))))

	func test_帯は橋の外側の辺の中点から出て_着地点の向かい合う辺の中点に入る():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		var path: PackedVector2Array = world.get_bridge_spans()[0]["path"]
		var edge_dir = chunk_a.get_edge_direction(Vector2i(1, 1))
		var out = chunk_a.hex_to_pixel(Hex.direction(edge_dir)) * 0.5
		var bridge_center = _screen(chunk_a, Vector2i(1, 1))
		var landing_center = _screen(chunk_b, Vector2i(-1, -1))
		assert_true(path[0].is_equal_approx(bridge_center + out), "橋の外側の辺の中点")
		assert_true(path[-1].is_equal_approx(landing_center - out), "着地点の向かい合う辺の中点")
		# 辺に垂直に出入りする（コンベアの入口とそのままつながる）
		assert_almost_eq((path[1] - path[0]).normalized().dot(out.normalized()), 1.0, 0.01)
		assert_almost_eq((path[-1] - path[-2]).normalized().dot(out.normalized()), 1.0, 0.01)

	func test_向かいに受け取り先が無ければつながっていない帯になる():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		assert_false(world.get_bridge_spans()[0]["connected"])

	func test_受け取り先があればつながった帯になる():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		chunk_b.place_piece(CONVEYOR, Vector2i(-1, -1))
		assert_true(world.get_bridge_spans()[0]["connected"])

	func test_隣のchunkからこちらへ向かう橋も描く():
		chunk_b.place_piece(BRIDGE_SCENE, Vector2i(-1, -1))
		var spans = world.get_bridge_spans()
		assert_eq(spans.size(), 1)
		assert_true(spans[0]["to"].is_equal_approx(_screen(chunk_a, Vector2i(1, 1))))

	func test_渡している途中のアイテムと進み具合が分かる():
		chunk_a.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		chunk_b.place_piece(CONVEYOR, Vector2i(-1, -1))
		var bridge = chunk_a.get_piece_at_hex(Vector2i(1, 1))
		bridge.add_item("iron_ore", 1)
		bridge.tick(TransferBuffer.TRANSFER_TIME * 0.5)
		var span = world.get_bridge_spans()[0]
		assert_eq(span["item"], "iron_ore")
		assert_almost_eq(span["progress"], 0.5, 0.01)

	func test_表示していないchunkどうしの橋は描かない():
		var far = world.create_chunk(Vector2i(3, 0))
		far.create_hex_grid(2)
		world.create_chunk(Vector2i(4, 0)).create_hex_grid(2)
		far.place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		assert_eq(world.get_bridge_spans(), [])

	func test_橋の帯は施設のタイルより奥_床より手前に描く():
		var overlay = world.get_node("BridgeOverlay")
		assert_lt(overlay.z_index, PortVisuals.PIECE_TILE_Z)
		assert_gt(overlay.z_index, 0)


class TestWorldChunkManagement:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_create_chunkで指定hexにChunkが生成される():
		var chunk = world.create_chunk(Vector2i(0, 0))
		assert_not_null(chunk)

	func test_get_chunkで作成済みChunkを取得できる():
		world.create_chunk(Vector2i(0, 0))
		assert_not_null(world.get_chunk(Vector2i(0, 0)))

	func test_get_chunkで存在しないhexはnullを返す():
		assert_null(world.get_chunk(Vector2i(1, 0)))

	func test_同じhexへのcreate_chunkは同一Chunkを返す():
		var a = world.create_chunk(Vector2i(0, 0))
		var b = world.create_chunk(Vector2i(0, 0))
		assert_eq(a, b)

	func test_create_chunkした直後のChunkはデフォルト非表示():
		var chunk = world.create_chunk(Vector2i(0, 0))
		assert_false(chunk.visible)

	func test_create_chunkしたhexはget_chunk_hexesで取得できる():
		world.create_chunk(Vector2i(0, 0))
		world.create_chunk(Vector2i(1, 0))
		var hexes = world.get_chunk_hexes()
		assert_eq(hexes.size(), 2)


class TestPlanetIntegration:
	extends GutTest

	var world
	var planet: Planet

	func before_each():
		world = World.new()
		add_child_autofree(world)
		planet = Planet.new(2, 1)
		world.setup_planet(planet)

	func test_setup_planetしたplanetを取得できる():
		assert_eq(world.get_planet(), planet)

	func test_get_map_hexesは未生成も含めplanetの全chunkを返す():
		assert_eq(world.get_map_hexes().size(), planet.get_chunk_hexes().size())

	func test_planet未設定ならget_map_hexesは生成済みchunkを返す():
		var plain_world = World.new()
		add_child_autofree(plain_world)
		plain_world.create_chunk(Vector2i(0, 0))
		assert_eq(plain_world.get_map_hexes().size(), 1)

	func test_planetのchunkは入るまで生成されない():
		assert_null(world.get_chunk(Vector2i(1, 0)))
		assert_eq(world.get_chunk_hexes().size(), 0)

	func test_未生成のchunkをアクティブにすると生成されて表示される():
		world.set_active_chunk(Vector2i(1, 0))
		var chunk = world.get_chunk(Vector2i(1, 0))
		assert_not_null(chunk)
		assert_true(chunk.visible)
		assert_eq(world.get_active_chunk(), chunk)

	func test_planet外のhexはアクティブにできない():
		world.set_active_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(5, 0))
		assert_null(world.get_chunk(Vector2i(5, 0)))
		assert_true(world.get_active_hex() == Vector2i(0, 0))

	func test_生成されたchunkにはバイオームの資源の鉱床がある():
		for hex in planet.get_chunk_hexes():
			var chunk = world.create_chunk(hex)
			var expected = planet.get_biome(hex).resource_type
			var count = 0
			for inner in chunk.get_all_hexes():
				var resource_type = chunk.get_hex_resource(inner)
				if resource_type != "":
					assert_eq(resource_type, expected, str(hex))
					count += 1
			assert_eq(count, World.DEPOSIT_SIZE, str(hex))


class TestWorldActiveChunk:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_初期状態ではget_active_chunkはnullを返す():
		assert_null(world.get_active_chunk())

	func test_set_active_chunkでそのChunkが表示される():
		world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		assert_true(world.get_chunk(Vector2i(0, 0)).visible)

	func test_set_active_chunkで隣でない前のアクティブChunkは非表示になる():
		world.create_chunk(Vector2i(0, 0))
		world.create_chunk(Vector2i(2, 0))
		world.set_active_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(2, 0))
		assert_false(world.get_chunk(Vector2i(0, 0)).visible)

	func test_get_active_chunkはアクティブなChunkを返す():
		var chunk = world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		assert_eq(world.get_active_chunk(), chunk)


class TestNeighborView:
	extends GutTest

	## ローカル画面では、アクティブな chunk の周りに隣の chunk も薄く描く

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)
		# 所有している chunk どうしの見え方を確かめる（所有していない隣は TestOwnership）
		world.territory.claim(Vector2i(0, 0))
		world.territory.claim(Vector2i(1, 0))

	# 画面上の位置（World の座標）
	func _screen_pos(chunk: Chunk, hex: Vector2i) -> Vector2:
		return chunk.position + chunk.hex_to_pixel(hex)

	func test_アクティブなchunkは原点にそのままの色で描かれる():
		world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var chunk = world.get_active_chunk()
		assert_eq(chunk.position, Vector2.ZERO)
		assert_eq(chunk.modulate, Color.WHITE)

	func test_隣のchunkは敷き詰めた位置に薄く描かれる():
		world.create_chunk(Vector2i(0, 0))
		var neighbor = world.create_chunk(Vector2i(1, 0))
		world.set_active_chunk(Vector2i(0, 0))
		assert_true(neighbor.visible)
		assert_ne(neighbor.position, Vector2.ZERO)
		assert_eq(neighbor.modulate, World.NEIGHBOR_MODULATE)

	func test_隣のchunkとは溝をはさんで辺の対応位置どうしが真正面に向かい合う():
		world.setup_planet(Planet.new(2, 1))
		world.set_active_chunk(Vector2i(0, 0))
		var active = world.get_active_chunk()
		for edge_hex in active.get_outer_hexes():
			var edge_dir = active.get_edge_direction(edge_hex)
			if edge_dir == -1:
				continue
			var chunk_hex = Hex.direction(ChunkTopology.to_world_direction(edge_dir))
			var neighbor = world.get_chunk(chunk_hex)
			var across = ChunkTopology.mirror_hex(edge_hex, edge_dir)
			var gap = _screen_pos(neighbor, across) - _screen_pos(active, edge_hex)
			var step = active.hex_to_pixel(Hex.DIAGONALS[edge_dir])
			assert_true(gap.is_equal_approx(step * World.gap_steps), str(edge_hex))

	func test_隣のchunkの床は背景と見分けられ_アクティブな床よりは暗い():
		var floor_color = HexStyle.FLOOR_COLOR
		var dimmed = floor_color * World.NEIGHBOR_MODULATE
		var background = ProjectSettings.get_setting(
			"rendering/environment/defaults/default_clear_color"
		)
		assert_gt(dimmed.get_luminance() - background.get_luminance(), 0.04, "背景に溶けない")
		assert_lt(dimmed.get_luminance(), floor_color.get_luminance() - 0.03, "アクティブと区別できる")

	func test_隣でないchunkは描かない():
		world.create_chunk(Vector2i(0, 0))
		var far = world.create_chunk(Vector2i(2, 0))
		world.set_active_chunk(Vector2i(0, 0))
		assert_false(far.visible)

	func test_アクティブを切り替えると位置と色が入れ替わる():
		var origin = world.create_chunk(Vector2i(0, 0))
		var east = world.create_chunk(Vector2i(1, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var east_position = east.position
		world.set_active_chunk(Vector2i(1, 0))
		assert_eq(east.position, Vector2.ZERO)
		assert_eq(east.modulate, Color.WHITE)
		assert_true(origin.visible)
		assert_true(origin.position.is_equal_approx(-east_position), "向きが逆になる")
		assert_eq(origin.modulate, World.NEIGHBOR_MODULATE)

	func test_隣のchunkの一覧を返す():
		world.create_chunk(Vector2i(0, 0))
		world.create_chunk(Vector2i(1, 0))
		world.create_chunk(Vector2i(2, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var hexes = world.get_neighbor_hexes()
		assert_eq(hexes.size(), 1)
		assert_true(hexes[0] == Vector2i(1, 0))

	func test_planetがあれば隣のchunkは見えるように生成される():
		world.setup_planet(Planet.new(2, 1))
		world.set_active_chunk(Vector2i(0, 0))
		assert_eq(world.get_chunk_hexes().size(), 7)
		for dir in range(6):
			assert_true(world.get_chunk(Hex.direction(dir)).visible)

	func test_planetの外には隣のchunkを作らない():
		world.setup_planet(Planet.new(1, 1))
		world.set_active_chunk(Vector2i(1, 0))
		for hex in world.get_chunk_hexes():
			assert_true(world.get_planet().has_chunk(hex), str(hex))
		assert_eq(world.get_neighbor_hexes().size(), 3)

	func test_画面上の位置から隣のchunkの施設も取得できる():
		world.create_chunk(Vector2i(0, 0))
		var neighbor = world.create_chunk(Vector2i(1, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var conveyor = load("res://scenes/components/piece/conveyor.tscn")
		neighbor.place_piece(conveyor, Vector2i(-2, 1))
		var pos = neighbor.position + neighbor.hex_to_pixel(Vector2i(-2, 1))
		assert_eq(world.get_piece_at_position(pos), neighbor.get_piece_at_hex(Vector2i(-2, 1)))

	func test_画面上の位置からアクティブなchunkの施設を取得できる():
		var chunk = world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var conveyor = load("res://scenes/components/piece/conveyor.tscn")
		chunk.place_piece(conveyor, Vector2i(1, 0))
		assert_eq(
			world.get_piece_at_position(chunk.hex_to_pixel(Vector2i(1, 0))),
			chunk.get_piece_at_hex(Vector2i(1, 0))
		)

	func test_何も無い位置ではnull():
		world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		assert_null(world.get_piece_at_position(Vector2(5000, 5000)))


class TestChunkExtent:
	extends GutTest

	## chunk の見た目の大きさ（中心から辺までの距離）。ワールドマップのタイルの大きさを合わせるのに使う

	var world
	var saved_gap_steps

	func before_each():
		saved_gap_steps = World.gap_steps
		world = World.new()
		add_child_autofree(world)
		world.create_chunk(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))

	func after_each():
		World.gap_steps = saved_gap_steps

	func test_辺のギザギザの間に来る_外周のマスの頂点とくぼみの間():
		var chunk = world.get_active_chunk()
		chunk.create_hex_grid(chunk.grid_radius)
		var normal = (
			chunk
			. hex_to_pixel(ChunkTopology.chunk_offset(Hex.direction(0), chunk.grid_radius, 1))
			. normalized()
		)
		var edge_center = 0.0
		for hex in chunk.get_all_hexes():
			edge_center = maxf(edge_center, chunk.hex_to_pixel(hex).dot(normal))
		var cell = HexTile.visual_circumradius()
		var inradius = world.get_chunk_inradius()
		assert_gt(inradius, edge_center + cell * 0.5, "くぼみより外")
		assert_lt(inradius, edge_center + cell, "頂点より内")

	func test_溝の幅を変えてもchunkの大きさは変わらない():
		World.gap_steps = 1
		var narrow = world.get_chunk_inradius()
		World.gap_steps = 3
		assert_eq(world.get_chunk_inradius(), narrow)


class TestOwnership:
	extends GutTest

	## 所有している chunk にだけ入れる。所有している chunk の隣は、戦って解放できる。

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)
		world.setup_planet(Planet.new(3, 77))

	func test_はじめはどのchunkも所有していない():
		assert_false(world.territory.is_owned(Vector2i(0, 0)))

	func test_claimするとそのchunkを所有する():
		world.territory.claim(Vector2i(0, 0))
		assert_true(world.territory.is_owned(Vector2i(0, 0)))
		assert_false(world.territory.is_owned(Vector2i(1, 0)))

	func test_所有しているchunkの隣は挑戦できる():
		world.territory.claim(Vector2i(0, 0))
		assert_true(world.territory.can_challenge(Vector2i(1, 0)))

	func test_所有しているchunkから離れたchunkは挑戦できない():
		world.territory.claim(Vector2i(0, 0))
		assert_false(world.territory.can_challenge(Vector2i(2, 0)))

	func test_所有しているchunkは挑戦できない():
		world.territory.claim(Vector2i(0, 0))
		assert_false(world.territory.can_challenge(Vector2i(0, 0)))

	func test_planetの外は挑戦できない():
		world.territory.claim(Vector2i(3, 0))
		assert_false(world.territory.can_challenge(Vector2i(4, 0)))

	func test_所有しているchunkの一覧を返す():
		world.territory.claim(Vector2i(0, 0))
		world.territory.claim(Vector2i(1, 0))
		world.territory.claim(Vector2i(1, 0))
		assert_eq(world.territory.get_owned_hexes().size(), 2)

	func test_所有しているchunkをバイオームごとに数える():
		world.territory.claim(Vector2i(0, 0))
		world.territory.claim(Vector2i(1, 0))
		var planet = world.get_planet()
		var expected := {}
		for hex in [Vector2i(0, 0), Vector2i(1, 0)]:
			var biome_id = planet.get_biome_id(hex)
			expected[biome_id] = expected.get(biome_id, 0) + 1
		assert_eq(world.territory.count_by_biome(), expected)

	func test_ローカル画面では所有していない隣のchunkを所有している隣より暗く描く():
		world.territory.claim(Vector2i(0, 0))
		world.territory.claim(Vector2i(1, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var owned = world.get_chunk(Vector2i(1, 0)).modulate
		var unowned = world.get_chunk(Vector2i(0, 1)).modulate
		assert_lt(unowned.v, owned.v)

	func test_解放した隣のchunkは描き直すと明るくなる():
		world.territory.claim(Vector2i(0, 0))
		world.set_active_chunk(Vector2i(0, 0))
		var before = world.get_chunk(Vector2i(1, 0)).modulate
		world.territory.claim(Vector2i(1, 0))
		assert_gt(world.get_chunk(Vector2i(1, 0)).modulate.v, before.v)


class TestPlayer:
	extends GutTest

	## プレイヤーキャラクターは、立っている chunk のマスの上に描く。
	## その chunk が画面に描かれていなければ隠す。

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)
		world.setup_planet(Planet.new(3, 1))
		world.set_active_chunk(Vector2i(0, 0))

	func _view() -> Node2D:
		return world.get_node("PlayerView")

	func test_置いたキャラクターを取得できる():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		assert_eq(world.player.chunk_hex, Vector2i(0, 0))
		assert_eq(world.player.hex, Vector2i(1, 0))

	func test_立っているマスの上に描く():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		assert_true(_view().visible)
		assert_eq(_view().position, chunk.hex_to_pixel(Vector2i(1, 0)))

	func test_置くマスにキャラクターが立っていれば押し出す():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		assert_true(world.push_player_out_of(Vector2i(0, 0), [Vector2i(1, 0)]))
		assert_eq(Hex.distance(world.player.hex, Vector2i(1, 0)), 1)
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		assert_eq(_view().position, world.player.position, "描く位置も動く")

	func test_置くマスに重ならなければ動かさない():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		assert_true(world.push_player_out_of(Vector2i(0, 0), [Vector2i(-2, 0)]))
		assert_eq(world.player.hex, Vector2i(1, 0))

	func test_別のchunkに置くならキャラクターは動かさない():
		world.place_player(Vector2i(1, 0), Vector2i(1, 0))
		assert_true(world.push_player_out_of(Vector2i(0, 0), [Vector2i(1, 0)]))
		assert_eq(world.player.hex, Vector2i(1, 0))

	func test_押し出せる場所が無ければfalseで動かさない():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		var all: Array[Vector2i] = world.get_chunk(Vector2i(0, 0)).get_all_hexes()
		assert_false(world.push_player_out_of(Vector2i(0, 0), all))
		assert_eq(world.player.hex, Vector2i(1, 0))

	func test_隣のchunkに立っていればその位置に描く():
		world.place_player(Vector2i(1, 0), Vector2i(0, 0))
		assert_true(_view().visible)
		assert_eq(_view().position, world.get_chunk(Vector2i(1, 0)).position)

	func test_今いるchunkが変わって並び直しても立っているマスの上に描く():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		world.set_active_chunk(Vector2i(1, 0))
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		assert_eq(_view().position, chunk.position + chunk.hex_to_pixel(Vector2i(1, 0)))

	func test_立っているchunkが描かれていなければ隠す():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		world.set_active_chunk(Vector2i(2, 0))
		assert_false(_view().visible)

	func test_施設より手前に描く():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		assert_gt(_view().z_index, 0)

	# ---- 歩く ----
	# マスに縛られず、押した向きへ自由に動く。通れないところでは、通れる向きに沿って滑る。

	func _center(hex: Vector2i) -> Vector2:
		return world.get_chunk(Vector2i(0, 0)).hex_to_pixel(hex)

	func test_押した向きへ自由に動く():
		world.place_player(Vector2i(0, 0), Vector2i(2, 0))
		assert_true(world.move_player_by(Vector2(10, 4)))
		assert_eq(world.player.position, _center(Vector2i(2, 0)) + Vector2(10, 4))

	func test_表示もすぐにその位置へ動く():
		world.place_player(Vector2i(0, 0), Vector2i(2, 0))
		world.move_player_by(Vector2(10, 4))
		assert_eq(_view().position, world.get_player_position())
		assert_eq(world.get_player_position(), _center(Vector2i(2, 0)) + Vector2(10, 4))

	func test_機械には入れない():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		chunk.place_piece(load("res://scenes/components/piece/smelter_t1.tscn"), Vector2i(2, 0))
		for i in range(20):
			world.move_player_by(Vector2(5, 0))
		assert_eq(world.player.hex, Vector2i(1, 0))

	func test_斜めに押して壁に当たると_通れる向きに沿って滑る():
		# 東の端に立ち、右下へ押す。右へは出られないが、下へは進む
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		var edge = Vector2i(chunk.grid_radius, -2)
		world.place_player(Vector2i(0, 0), edge)
		var before = world.player.position
		for i in range(5):
			world.move_player_by(Vector2(5, 5))
		assert_gt(world.player.position.y, before.y)
		assert_eq(world.player.chunk_hex, Vector2i(0, 0))

	func test_ハブの斜めの辺に当たっても_辺に沿って滑って進む():
		# ハブ（原点）の左下で、体の上の端がハブの斜めの辺にかかる高さから右へ押す
		var hub_piece = load("res://scenes/components/piece/hub.tscn")
		world.get_chunk(Vector2i(0, 0)).place_piece(hub_piece, Vector2i(0, 0))
		world.place_player(Vector2i(0, 0), Vector2i(-1, 1))
		world.move_player_to(_center(Vector2i(-1, 1)) + Vector2(0, -10))
		for i in range(40):
			world.move_player_by(Vector2(4, 0))
		assert_gt(world.player.position.x, _center(Vector2i(0, 1)).x, "ハブの下を通り抜ける")

	func test_chunkの端から外へは出られない():
		var chunk: Chunk = world.get_chunk(Vector2i(0, 0))
		world.place_player(Vector2i(0, 0), Vector2i(chunk.grid_radius, 0))
		for i in range(20):
			world.move_player_by(Vector2(5, 0))
		assert_eq(world.player.hex, Vector2i(chunk.grid_radius, 0))

	# ---- chunk の間を渡る ----
	# 辺のマスに立つと、その辺の向こうの chunk の、向かい合うマスへ渡れる。

	# 東隣 (1, 0) の chunk に面した辺（SE）の、角でないマス
	func _east_edge_hex() -> Vector2i:
		return Vector2i(2, Chunk.DEFAULT_RADIUS - 2)

	func test_辺のマスに立つと_向こうのchunkの向かいのマスへ渡れる():
		world.place_player(Vector2i(0, 0), _east_edge_hex())
		var crossing = world.get_player_crossing()
		assert_eq(crossing["chunk_hex"], Vector2i(1, 0))
		assert_eq(crossing["hex"], ChunkTopology.mirror_hex(_east_edge_hex(), 5))

	func test_内側のマスや角からは渡れない():
		world.place_player(Vector2i(0, 0), Vector2i(1, 0))
		assert_true(world.get_player_crossing().is_empty())
		world.place_player(Vector2i(0, 0), Vector2i(Chunk.DEFAULT_RADIUS, 0))
		assert_true(world.get_player_crossing().is_empty(), "角は2つの辺にまたがるので渡らない")

	func test_渡るとキャラクターは向こうのchunkの向かいのマスに立つ():
		world.place_player(Vector2i(0, 0), _east_edge_hex())
		assert_true(world.cross_player())
		assert_eq(world.player.chunk_hex, Vector2i(1, 0))
		assert_eq(world.player.hex, ChunkTopology.mirror_hex(_east_edge_hex(), 5))

	func test_向かいのマスに機械があれば渡れない():
		world.place_player(Vector2i(0, 0), _east_edge_hex())
		var east: Chunk = world.get_chunk(Vector2i(1, 0))
		east.place_piece(
			load("res://scenes/components/piece/smelter_t1.tscn"),
			world.get_player_crossing()["hex"]
		)
		assert_false(world.cross_player())
		assert_eq(world.player.chunk_hex, Vector2i(0, 0))
