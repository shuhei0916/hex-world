# gdlint:disable=constant-name
extends GutTest

const Chunk = preload("res://scenes/components/chunk/chunk.gd")
const MINER_SCENE = preload("res://scenes/components/piece/miner_t2.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")


class TestGridLogic:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.clear_grid()

	func test_指定した範囲のグリッドを生成できる():
		gm.create_hex_grid(2)
		assert_eq(gm.get_grid_hex_count(), 19, "半径2のグリッドは19マスであるべき")
		assert_true(gm.is_inside_grid(Hex.new(0, 0)))
		assert_false(gm.is_inside_grid(Hex.new(3, 0)), "範囲外は登録されていないべき")

	func test_グリッド状態を完全にクリアできる():
		gm.register_grid_hex(Hex.new(0, 0))
		gm.occupy(Hex.new(0, 0))
		gm.clear_grid()
		assert_false(gm.is_inside_grid(Hex.new(0, 0)))
		assert_false(gm.is_occupied(Hex.new(0, 0)))


class TestPiecePlacement:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_place_pieceするとpiece_placedシグナルが発火する():
		watch_signals(gm)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		assert_signal_emitted(gm, "piece_placed")

	func test_remove_piece_atが成功するとpiece_removedシグナルが発火する():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		watch_signals(gm)
		gm.remove_piece_at(Hex.new(0, 0))
		assert_signal_emitted(gm, "piece_removed")

	func test_remove_piece_atが失敗したときはpiece_removedは発火しない():
		watch_signals(gm)
		gm.remove_piece_at(Hex.new(0, 0))  # 何も置かれていない
		assert_signal_not_emitted(gm, "piece_removed")

	func test_MINERシーンを使うとInputノードがない():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_null(piece.get_node_or_null("ItemAcceptor"), "MINERはInputノードを持たないはず")

	func test_有効な場所にピースを配置できる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		assert_true(gm.is_occupied(Hex.new(0, 0)))
		assert_not_null(gm.get_piece_at_hex(Hex.new(0, 0)))

	func test_占有済みまたは範囲外には配置できない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var shape: Array[Hex] = [Hex.new(0, 0)]
		assert_false(gm.can_place(shape, Hex.new(0, 0)), "占有済み")
		assert_false(gm.can_place(shape, Hex.new(5, 5)), "範囲外")

	func test_ピースを削除すると占有が解除されノードも解放される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(0, 0))
		assert_false(gm.is_occupied(Hex.new(0, 0)))
		assert_true(piece.is_queued_for_deletion())

	func test_配置時にピースの色でHexTileが生成される():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		for child in piece.get_children():
			if child is HexTile:
				assert_eq((child as HexTile).get_color(), piece.piece_color)
				return
		fail_test("ピースにHexTileが存在しない")

	func test_機械の出力アイテムは地面タイルより手前に描画される():
		gm.place_piece(SMELTER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		var ground = gm.find_hex_tile(Hex.new(0, 0))
		var icon = piece.get_node("ItemEjectorVisual/ItemIcon")
		assert_lt(ground.z_index, icon.z_index)

	func test_コンベアのベルトは地面タイルより手前に描画される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		var view = piece.get_node("ConveyorVisuals")
		var ground = gm.find_hex_tile(Hex.new(0, 0))
		assert_lt(ground.z_index, view.z_index)


class TestNeighbors:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_指定した方向の隣接ピースを取得できる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1))
		var piece_b = gm.get_piece_at_hex(Hex.new(1, -1))
		assert_eq(gm.get_neighbor_piece(Hex.new(0, 0), 1), piece_b)
		assert_null(gm.get_neighbor_piece(Hex.new(0, 0), 3), "存在しない方向はnull")

	func test_出力ポートの先にピースがある場合は搬送先として登録される():
		# CONVEYOR at (0,0): 1ヘックス、port_direction=0(East) → neighbor (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(target in source.get_connected_pieces())

	func test_ポートが向いていない隣接ピースは搬送先に登録されない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, -1))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(0, -1))
		assert_false(target in source.get_connected_pieces())

	func test_ピース削除時に周囲の搬送先リストが自動更新される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(1, 0))
		assert_eq(source.get_connected_pieces().size(), 0, "削除後は接続が切れているべき")

	func test_自然な分岐後コンベアAのConveyorVisualsは2本のパスを持つ():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))  # A: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))  # B: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)  # C: NE
		var a = gm.get_piece_at_hex(Hex.new(0, 0))
		var visuals = a.get_node("ConveyorVisuals")
		assert_eq(visuals._paths.size(), 2, "Aの分岐後はベジェパスが2本あるべき")

	func test_コンベアBの入力方向がAを向くときAはBを出力先に自動追加する():
		# A at (0,0) East(dir=0)、B at (1,0) East、C at (1,-1) NE(dir=1) は自然な分岐
		# CONVEYOR のデフォルト port_direction=0(East)。rotation=5 → (0-5+6)%6=1(NE)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))  # A: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))  # B: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)  # C: NE（Aから見てNE方向にあり、NE向き）
		var a = gm.get_piece_at_hex(Hex.new(0, 0))
		var c = gm.get_piece_at_hex(Hex.new(1, -1))
		assert_true(c in a.get_connected_pieces(), "AはCを出力先として持つべき（自然な分岐）")


class TestItemTransfer:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_出力インベントリが満杯の状態で接続するとアイテムが転送される():
		# 機械を設置し、出力を満杯にしてから受け取り先を接続する
		# SMELTER at (-1,2): port at (0,0) → absolute (-1,2), direction E → neighbor (0,2)
		gm.place_piece(SMELTER_SCENE, Hex.new(-1, 2))
		var source = gm.get_piece_at_hex(Hex.new(-1, 2))
		source.add_to_output("iron_plate", 1)  # 出力容量はレシピ1回分(1)なので1個で満杯

		# 接続先を後から設置 → この時点で _push_items() が呼ばれないのがバグ
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 2))
		var chest = gm.get_piece_at_hex(Hex.new(0, 2))

		source.tick(1.0)  # スライド完了→排出
		assert_gt(chest.get_item_count("iron_plate"), 0, "満杯状態で接続してもアイテムが転送されるべき")

	func test_搬送完了済みのコンベアに後から接続先を置くと次のtickで転送される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		source.add_item("iron_plate", 1)
		source.get_node("ConveyorLogic").tick(0.5)  # 接続先がないので保持したまま

		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		source.get_node("ConveyorLogic").tick(0.1)  # 搬送済みなので追加の待ち時間は不要

		assert_eq(chest.get_item_count("iron_plate"), 1)


class TestOuterHexes:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_get_outer_hexesは外縁ヘックスのみを返す():
		var outer = gm.get_outer_hexes()
		for hex in outer:
			var max_coord = max(abs(hex.q), abs(hex.r), abs(hex.s))
			assert_eq(max_coord, 2, "外縁ヘックスは max(|q|,|r|,|s|)==radius であるべき")

	func test_get_outer_hexesは内側のヘックスを含まない():
		var outer = gm.get_outer_hexes()
		for hex in outer:
			var max_coord = max(abs(hex.q), abs(hex.r), abs(hex.s))
			assert_true(max_coord >= 2, "内側ヘックスが含まれていてはならない")


class TestEdgeDirection:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_辺ヘックスは属する辺の方向を返す():
		# q=+R の辺（角以外）は東(0)の辺に属する
		assert_eq(gm.get_edge_direction(Hex.new(2, -1, -1)), 0)

	func test_対辺の点対称位置は逆方向を返す():
		# q=-R の辺（東の辺の点対称）は西(3)の辺に属する
		assert_eq(gm.get_edge_direction(Hex.new(-2, 1, 1)), 3)

	func test_角ヘックスはマイナス1を返す():
		# 座標2つが±R に達する角はどの辺にも属さない
		assert_eq(gm.get_edge_direction(Hex.new(2, -2, 0)), -1)

	func test_内側ヘックスはマイナス1を返す():
		assert_eq(gm.get_edge_direction(Hex.new(0, 0, 0)), -1)

	func test_SENDERは内側ヘックスに設置できない():
		var shape: Array = [Hex.new(0, 0, 0)]
		assert_false(gm.can_place(shape, Hex.new(0, 0, 0), PieceData.Type.SENDER))

	func test_SENDERは辺ヘックスに設置できる():
		var shape: Array = [Hex.new(0, 0, 0)]
		assert_true(gm.can_place(shape, Hex.new(2, -1, -1), PieceData.Type.SENDER))

	func test_RECEIVERは角ヘックスに設置できない():
		var shape: Array = [Hex.new(0, 0, 0)]
		assert_false(gm.can_place(shape, Hex.new(2, -2, 0), PieceData.Type.RECEIVER))

	func test_通常ピースは内側ヘックスに設置できる():
		var shape: Array = [Hex.new(0, 0, 0)]
		assert_true(gm.can_place(shape, Hex.new(0, 0, 0), PieceData.Type.CONVEYOR))


class TestReceiverHints:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_show_receiver_hintsで指定タイルがハイライトされる():
		gm.show_receiver_hints([Hex.new(-2, 1, 1)])
		assert_true(gm.find_hex_tile(Hex.new(-2, 1, 1)).is_highlighted)

	func test_再表示で前回のハイライトはクリアされる():
		gm.show_receiver_hints([Hex.new(-2, 1, 1)])
		gm.show_receiver_hints([])
		assert_false(gm.find_hex_tile(Hex.new(-2, 1, 1)).is_highlighted)


class TestOreDeposits:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_get_hex_resourceが登録済みヘックスのリソース名を返す():
		gm.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		assert_eq(gm.get_hex_resource(Hex.new(0, 0)), "iron_ore")

	func test_get_hex_resourceが未登録ヘックスに空文字を返す():
		assert_eq(gm.get_hex_resource(Hex.new(0, 0)), "")

	func test_generate_ore_depositsがN個をiron_oreとして登録する():
		gm.generate_ore_deposits(3)
		var count = 0
		for hex in gm.get_inner_hexes():
			if gm.get_hex_resource(hex) == "iron_ore":
				count += 1
		assert_eq(count, 3)

	func test_generate_ore_depositsが外縁ヘックスを含まない():
		gm.generate_ore_deposits(100)
		for hex in gm.get_outer_hexes():
			assert_eq(gm.get_hex_resource(hex), "", "外縁に鉱床があってはならない")


class TestMinerConstraint:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_MINER_を非鉱床ヘックスに設置するとレシピがnull():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		var crafter = piece.get_node_or_null("Crafter")
		assert_null(crafter.current_recipe)

	func test_MINER_を2鉱床ヘックス上に設置するとoutput_multiplierが2():
		gm.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		gm.mark_resource_hex(Hex.new(0, 1), "iron_ore")
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		var crafter = piece.get_node_or_null("Crafter")
		assert_eq(crafter.output_multiplier, 2)

	func test_MINER_を4鉱床ヘックス上に設置するとoutput_multiplierが4():
		gm.mark_resource_hex(Hex.new(0, 0), "iron_ore")
		gm.mark_resource_hex(Hex.new(0, 1), "iron_ore")
		gm.mark_resource_hex(Hex.new(1, 0), "iron_ore")
		gm.mark_resource_hex(Hex.new(1, 1), "iron_ore")
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		var crafter = piece.get_node_or_null("Crafter")
		assert_eq(crafter.output_multiplier, 4)


class TestHubProtection:
	extends GutTest

	const HUB_SCENE = preload("res://scenes/components/piece/hub.tscn")

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_HUBピースはremove_piece_atで削除できない():
		gm.place_piece(HUB_SCENE, Hex.new(0, 0))
		var result = gm.remove_piece_at(Hex.new(0, 0))
		assert_false(result)


class TestHubPlacement:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_place_hubはHex_0_0にハブを配置する():
		gm.place_hub("iron_plate", 10)
		assert_eq(gm.get_piece_at_hex(Hex.new(0, 0)).piece_type, PieceData.Type.HUB)

	func test_generate_ore_depositsはhub設置済みヘックスを鉱床として登録しない():
		gm.place_hub("iron_plate", 10)
		gm.generate_ore_deposits(100)
		assert_eq(gm.get_hex_resource(Hex.new(0, 0)), "")
