extends GutTest

const WorldMapView = preload("res://scenes/components/world/world_map_view.gd")
const World = preload("res://scenes/components/world/world.gd")


class TestWorldMapView:
	extends GutTest

	const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")
	const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

	var view
	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)
		world.create_chunk(Vector2i(0, 0))
		world.create_chunk(Vector2i(1, 0))
		view = WorldMapView.new()
		add_child_autofree(view)

	func test_setupでチャンク数と同数のChunkTileが生成される():
		view.setup(world)
		assert_eq(view.get_tile_count(), 2)

	func test_異なるhexのタイルは異なる位置に配置される():
		view.setup(world)
		var pos0 = view.get_tile_position(Vector2i(0, 0))
		var pos1 = view.get_tile_position(Vector2i(1, 0))
		assert_ne(pos0, pos1)

	func test_set_active_chunkでそのタイルがアクティブになる():
		view.setup(world)
		view.set_active_chunk(Vector2i(0, 0))
		assert_true(view.get_tile_active(Vector2i(0, 0)))

	func test_set_active_chunk切り替えで前のタイルが非アクティブになる():
		view.setup(world)
		view.set_active_chunk(Vector2i(0, 0))
		view.set_active_chunk(Vector2i(1, 0))
		assert_false(view.get_tile_active(Vector2i(0, 0)))

	func test_タイル中心位置を渡すと対応するhexを返す():
		view.setup(world)
		var center = view.get_tile_position(Vector2i(0, 0))
		assert_true(view.chunk_at_local_pos(center) == Vector2i(0, 0))

	func test_タイルが存在しない位置ではnullを返す():
		view.setup(world)
		assert_null(view.chunk_at_local_pos(Vector2(9999, 9999)))

	func _route(from: Vector2i, to: Vector2i, items: Dictionary = {}) -> Dictionary:
		return {"from": from, "to": to, "items": items}

	func test_輸送路の数だけカードが出る():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		assert_eq(view.get_transfer_card_count(), 1)

	func test_輸送路がなければカードは出ない():
		view.setup(world)
		view.refresh_transfers([])
		assert_eq(view.get_transfer_card_count(), 0)

	func test_出し直すたびに前回分のカードは消える():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		assert_eq(view.get_transfer_card_count(), 1)

	func test_set_hovered_chunkでそのタイルがホバー状態になる():
		view.setup(world)
		view.set_hovered_chunk(Vector2i(0, 0))
		assert_true(view.get_tile_hovered(Vector2i(0, 0)))

	func test_set_hovered_chunk切り替えで前のタイルのホバーが解除される():
		view.setup(world)
		view.set_hovered_chunk(Vector2i(0, 0))
		view.set_hovered_chunk(Vector2i(1, 0))
		assert_false(view.get_tile_hovered(Vector2i(0, 0)))

	func test_set_hovered_chunkにnullを渡すとホバーが解除される():
		view.setup(world)
		view.set_hovered_chunk(Vector2i(0, 0))
		view.set_hovered_chunk(null)
		assert_false(view.get_tile_hovered(Vector2i(0, 0)))

	func test_片道のカードは2つのタイルの中間に置く():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		var pos0 = view.get_tile_position(Vector2i(0, 0))
		var pos1 = view.get_tile_position(Vector2i(1, 0))
		assert_eq(view.get_transfer_card(0).position, (pos0 + pos1) / 2.0)

	func test_カードの矢印は運ぶ向きを指す():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		var pos0 = view.get_tile_position(Vector2i(0, 0))
		var pos1 = view.get_tile_position(Vector2i(1, 0))
		assert_almost_eq(view.get_transfer_card(0).direction.angle(), (pos1 - pos0).angle(), 0.001)

	func test_往復するときは_それぞれ進む向きの右側へずらして重ならないようにする():
		view.setup(world)
		view.refresh_transfers(
			[_route(Vector2i(0, 0), Vector2i(1, 0)), _route(Vector2i(1, 0), Vector2i(0, 0))]
		)
		var mid = (
			(view.get_tile_position(Vector2i(0, 0)) + view.get_tile_position(Vector2i(1, 0))) / 2.0
		)
		var go = view.get_transfer_card(0)
		var back = view.get_transfer_card(1)
		var right_of_go = go.direction.orthogonal() * -1.0  # 画面は y が下向き
		assert_gt((go.position - mid).dot(right_of_go), 0.0, "行きは行きの右")
		assert_lt((back.position - mid).dot(right_of_go), 0.0, "帰りは反対側")
		assert_gt(go.position.distance_to(back.position), WorldMapView.LANE_OFFSET)

	func test_カードには品目と毎分の個数を多い順に並べる():
		view.setup(world)
		view.refresh_transfers(
			[_route(Vector2i(0, 0), Vector2i(1, 0), {"copper_ore": 15.0, "iron_ore": 59.6})]
		)
		assert_eq(
			view.get_transfer_card(0).get_rows(), [["iron_ore", "60/分"], ["copper_ore", "15/分"]]
		)

	func test_まだ何も運んでいない輸送路は矢印だけ():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		assert_eq(view.get_transfer_card(0).get_rows(), [])

	func test_表示中は一定時間ごとにWorldから輸送を読み直す():
		view.setup(world)
		view.visible = true
		var chunk_b = world.get_chunk(Vector2i(1, 0))
		world.get_chunk(Vector2i(0, 0)).create_hex_grid(2)
		chunk_b.create_hex_grid(2)
		world.get_chunk(Vector2i(0, 0)).place_piece(BRIDGE_SCENE, Vector2i(1, 1))
		chunk_b.place_piece(CONVEYOR, Vector2i(-1, -1))
		assert_eq(view.get_transfer_card_count(), 0, "置いた直後はまだ")
		view._process(WorldMapView.REFRESH_INTERVAL)
		assert_eq(view.get_transfer_card_count(), 1)

	func test_カードはタイルより手前に描く():
		view.setup(world)
		view.refresh_transfers([_route(Vector2i(0, 0), Vector2i(1, 0))])
		assert_gt(view.get_transfer_card(0).z_index, 0)


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
		# 所有している chunk の見え方を確かめる（所有していない chunk は TestFog）
		for hex in planet.get_chunk_hexes():
			world.territory.claim(hex)
		view = WorldMapView.new()
		add_child_autofree(view)
		view.setup(world)

	func test_planetの全chunkのタイルが生成される():
		assert_eq(view.get_tile_count(), planet.get_chunk_hexes().size())

	func test_タイルはそのchunkのバイオーム色で塗られる():
		for hex in planet.get_chunk_hexes():
			assert_eq(view.get_tile_color(hex), planet.get_biome(hex).map_color, str(hex))

	func test_ホバー中のchunkのバイオーム名と資源名が表示される():
		var hex = Vector2i(1, 0)
		view.set_hovered_chunk(hex)
		var biome = planet.get_biome(hex)
		var text = view.get_hover_info_text()
		assert_string_contains(text, biome.display_name)
		assert_string_contains(text, ItemDB.get_item(biome.resource_type).display_name)

	func test_原点のchunkにホバーしても情報が表示される():
		view.set_hovered_chunk(Vector2i(0, 0))
		assert_string_contains(
			view.get_hover_info_text(), planet.get_biome(Vector2i(0, 0)).display_name
		)

	func test_ホバー解除で情報表示が消える():
		view.set_hovered_chunk(Vector2i(1, 0))
		view.set_hovered_chunk(null)
		assert_eq(view.get_hover_info_text(), "")

	func test_再setupしても情報表示は1つだけ():
		view.setup(world)
		view.set_hovered_chunk(Vector2i(1, 0))
		assert_ne(view.get_hover_info_text(), "")
		assert_eq(view.get_tile_count(), planet.get_chunk_hexes().size())


class TestFog:
	extends GutTest

	## 所有していない chunk は霧に隠す。所有している chunk の隣だけは、
	## 何が採れるかを見せて、戦って解放できることを示す

	var owned := Vector2i(0, 0)
	var frontier := Vector2i(1, 0)
	var far := Vector2i(2, 0)
	var view
	var world
	var planet: Planet

	func before_each():
		world = World.new()
		add_child_autofree(world)
		planet = Planet.new(2, 1)
		world.setup_planet(planet)
		world.territory.claim(owned)
		view = WorldMapView.new()
		add_child_autofree(view)
		view.setup(world)

	func after_each():
		ColorTheme.set_mode(ColorTheme.Mode.DARK)

	func test_所有しているchunkはバイオーム色で塗られる():
		assert_eq(view.get_tile_color(owned), planet.get_biome(owned).map_color)

	func test_挑戦できるchunkはバイオーム色を暗くした色で塗られる():
		var biome_color = planet.get_biome(frontier).map_color
		var expected = biome_color.darkened(WorldMapView.FRONTIER_DARKEN)
		assert_true(view.get_tile_color(frontier).is_equal_approx(expected))

	func test_離れたchunkはバイオームに関係なく霧の色で塗られる():
		assert_eq(view.get_tile_color(far), ColorTheme.color(&"fog"))

	func test_配色を切り替えると紙に寄せた淡い色で塗り直す():
		ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
		view.apply_color_theme()
		var biome_color = planet.get_biome(owned).map_color
		assert_eq(view.get_tile_color(owned), ColorTheme.map_color(biome_color))
		assert_eq(view.get_tile_color(far), ColorTheme.LIGHT[&"fog"])

	func test_ライトでは挑戦できるchunkは霧の色に寄せて沈める():
		ColorTheme.set_mode(ColorTheme.Mode.LIGHT)
		view.apply_color_theme()
		var fog := ColorTheme.color(&"fog")
		var biome_color := ColorTheme.map_color(planet.get_biome(frontier).map_color)
		var shown: Color = view.get_tile_color(frontier)
		assert_lt(_distance(shown, fog), _distance(biome_color, fog) * 0.6)

	func _distance(a: Color, b: Color) -> float:
		return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

	func test_挑戦できるchunkにホバーすると採れる資源と戦って解放できることを表示する():
		view.set_hovered_chunk(frontier)
		var text = view.get_hover_info_text()
		assert_string_contains(text, planet.get_biome(frontier).display_name)
		assert_string_contains(text, "戦って解放")

	func test_所有しているchunkのホバーには戦って解放と出さない():
		view.set_hovered_chunk(owned)
		assert_false(view.get_hover_info_text().contains("戦って解放"))

	func test_霧のchunkにホバーしてもバイオームは明かさない():
		view.set_hovered_chunk(far)
		assert_eq(view.get_hover_info_text(), "未踏")

	func test_解放したあとsetupし直すと霧が晴れる():
		world.territory.claim(frontier)
		view.setup(world)
		assert_eq(view.get_tile_color(frontier), planet.get_biome(frontier).map_color)
		assert_ne(view.get_tile_color(far), ColorTheme.color(&"fog"), "隣になった chunk が見える")


class TestTilesTouch:
	extends GutTest

	## ワールドマップは地続きの大地として見せるので、タイルは隣と隙間なく接する
	## （ローカル画面の chunk 間の溝はワールドマップには持ち込まない）

	var view
	var world
	var saved_gap_steps

	func before_each():
		saved_gap_steps = World.gap_steps
		world = World.new()
		add_child_autofree(world)
		world.create_chunk(Vector2i(0, 0))
		world.create_chunk(Vector2i(1, 0))
		world.set_active_chunk(Vector2i(0, 0))
		view = WorldMapView.new()
		add_child_autofree(view)

	func after_each():
		World.gap_steps = saved_gap_steps

	func test_タイルは隣のタイルと隙間なく接する():
		view.setup(world)
		var spacing = view.get_tile_spacing()
		assert_almost_eq(view.get_tile_inradius(Vector2i(1, 0)) * 2.0, spacing, 0.0001)

	func test_溝の幅を変えてもタイルは隙間なく接する():
		World.gap_steps = 3
		view.setup(world)
		var spacing = view.get_tile_spacing()
		assert_almost_eq(view.get_tile_inradius(Vector2i(0, 0)) * 2.0, spacing, 0.0001)
