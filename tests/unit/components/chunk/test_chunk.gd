# gdlint:disable=constant-name
extends GutTest

const Island = preload("res://scenes/components/chunk/chunk.gd")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")


class TestGridLogic:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
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
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_MINERシーンを使うとInputノードがない():
		gm.place_piece(MINER_SCENE, Hex.new(0, 0))
		var piece = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_null(piece.get_node_or_null("Input"), "MINERはInputノードを持たないはず")

	func test_有効な場所にピースを配置できる():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		assert_true(gm.is_occupied(Hex.new(0, 0)))
		assert_not_null(gm.get_piece_at_hex(Hex.new(0, 0)))

	func test_占有済みまたは範囲外には配置できない():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
		var shape: Array[Hex] = [Hex.new(0, 0)]
		assert_false(gm.can_place(shape, Hex.new(0, 0)), "占有済み")
		assert_false(gm.can_place(shape, Hex.new(5, 5)), "範囲外")

	func test_ピースを削除すると占有が解除されノードも解放される():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
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


class TestNeighbors:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_指定した方向の隣接ピースを取得できる():
		gm.place_piece(CHEST_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, -1))
		var piece_b = gm.get_piece_at_hex(Hex.new(1, -1))
		assert_eq(gm.get_neighbor_piece(Hex.new(0, 0), 1), piece_b)
		assert_null(gm.get_neighbor_piece(Hex.new(0, 0), 3), "存在しない方向はnull")

	func test_出力ポートの先にピースがある場合は搬送先として登録される():
		# CONVEYOR at (0,0): 1ヘックス、port_direction=0(East) → neighbor (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(target in source.output.connected_pieces)

	func test_ポートが向いていない隣接ピースは搬送先に登録されない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, -1))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		var target = gm.get_piece_at_hex(Hex.new(0, -1))
		assert_false(target in source.output.connected_pieces)

	func test_ピース削除時に周囲の搬送先リストが自動更新される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		gm.remove_piece_at(Hex.new(1, 0))
		assert_eq(source.output.connected_pieces.size(), 0, "削除後は接続が切れているべき")


class TestItemTransfer:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_出力インベントリが満杯の状態で接続するとアイテムが転送される():
		# コンベアを設置し、出力を満杯にしてから受け取り先を接続する
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var source = gm.get_piece_at_hex(Hex.new(0, 0))
		source.add_to_output("iron_plate", 20)  # 満杯（capacity=20）

		# 接続先を後から設置 → この時点で _push_items() が呼ばれないのがバグ
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))

		assert_gt(chest.get_item_count("iron_plate"), 0, "満杯状態で接続してもアイテムが転送されるべき")


class TestOuterHexes:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
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


class TestOreDeposits:
	extends GutTest

	var gm

	func before_each():
		gm = Island.new()
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
		gm = Island.new()
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


class TestDeliveryProtection:
	extends GutTest

	const DELIVERY_SCENE = preload("res://scenes/components/piece/delivery.tscn")

	var gm

	func before_each():
		gm = Island.new()
		add_child_autofree(gm)
		gm.create_hex_grid(2)

	func test_DELIVERYピースはremove_piece_atで削除できない():
		gm.place_piece(DELIVERY_SCENE, Hex.new(0, 0))
		var result = gm.remove_piece_at(Hex.new(0, 0))
		assert_false(result)
