# gdlint:disable=constant-name
extends GutTest

const BALANCER_SCENE = preload("res://scenes/components/piece/balancer.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const Chunk = preload("res://scenes/components/chunk/chunk.gd")


class TestConveyorLogicRoundRobin:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_ConveyorLogicは接続先が2つのときget_target_directionで次の排出方向を返す():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))  # A: East
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))  # B: East（East方向へ続く）
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 5)  # C: NE（自然な分岐）
		var a = gm.get_piece_at_hex(Hex.new(0, 0))
		a.add_item("iron_ore", 1)
		assert_ne(a.get_node("ConveyorLogic").get_target_direction(), -1)


class TestBalancerPorts:
	extends GutTest

	func test_Balancerはget_output_portsが2ポートを返す():
		var balancer = BALANCER_SCENE.instantiate()
		add_child_autofree(balancer)
		balancer.setup(0)
		assert_eq(balancer.get_output_ports().size(), 2)

	func test_BalancerのデフォルトポートはEastとSE():
		var balancer = BALANCER_SCENE.instantiate()
		add_child_autofree(balancer)
		balancer.setup(0)
		var ports = balancer.get_output_ports()
		assert_eq(ports[0]["direction"], 0)
		assert_eq(ports[1]["direction"], 5)


class TestBalancerConnection:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_Balancer配置後にconnected_piecesに2ピースが接続される():
		gm.place_piece(BALANCER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1))
		var balancer = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(balancer.get_connected_pieces().size(), 2)

	func test_アイテムがラウンドロビンで2方向に分配される():
		gm.place_piece(BALANCER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1))
		var balancer = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var chest_se = gm.get_piece_at_hex(Hex.new(0, 1))
		balancer.add_item("iron_ore", 1)
		balancer.get_node("ConveyorLogic").tick(0.5)
		balancer.add_item("iron_ore", 1)
		balancer.get_node("ConveyorLogic").tick(0.5)
		assert_eq(chest_e.get_item_count("iron_ore") + chest_se.get_item_count("iron_ore"), 2)

	func test_片側のみ接続時_保持アイテムは接続側の出力方向に向く():
		# SE(0,1) のみ接続。表示・実排出ともに SE(方向5) を指すべき（食い違い解消）。
		gm.place_piece(BALANCER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1))
		var balancer = gm.get_piece_at_hex(Hex.new(0, 0))
		balancer.add_item("iron_ore", 1)
		assert_eq(balancer.get_node("ConveyorLogic").get_target_direction(), 5)

	func test_連続するアイテムは異なる出力側に飛び出る():
		gm.place_piece(BALANCER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1))
		var balancer = gm.get_piece_at_hex(Hex.new(0, 0))
		var visual = balancer.get_node("ItemEjectorVisual")
		var logic = balancer.get_node("ConveyorLogic")
		balancer.add_item("iron_ore", 1)
		logic.tick(0.25)  # スライド途中(まだ排出しない)
		visual.update_item_icon()
		var pos1 = visual.get_node("ItemIcon").position
		logic.tick(0.25)  # progress=1 → 1個目を排出 → buffer 空
		visual.update_item_icon()
		balancer.add_item("iron_ore", 1)
		logic.tick(0.25)  # 2個目スライド途中
		visual.update_item_icon()
		var pos2 = visual.get_node("ItemIcon").position
		assert_ne(pos1, pos2)

	func test_2アイテム送ると両方の接続先に1個ずつ届く():
		# Balancer(0,0) → conveyor_e(1,0) と conveyor_se(0,1) に分岐
		gm.place_piece(BALANCER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East出力
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1), 1)  # SE→NE... rotation確認
		gm.place_piece(CONVEYOR_SCENE, Hex.new(2, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 1))
		var balancer = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var conv_se = gm.get_piece_at_hex(Hex.new(0, 1))
		assert_eq(balancer.get_connected_pieces().size(), 2, "Balancerは2方向に接続されるべき")
		balancer.add_item("iron_ore", 1)
		balancer.get_node("ConveyorLogic").tick(0.5)
		balancer.add_item("iron_ore", 1)
		balancer.get_node("ConveyorLogic").tick(0.5)
		var total_in_conveyors = (
			conv_e.get_item_count("iron_ore") + conv_se.get_item_count("iron_ore")
		)
		assert_eq(total_in_conveyors, 2, "2アイテムが両コンベアに1個ずつ届くべき")


class TestBalancerVisuals:
	extends GutTest

	var balancer: Piece

	func before_each():
		balancer = BALANCER_SCENE.instantiate()
		add_child_autofree(balancer)
		balancer.setup(0)

	func test_BalancerはConveyorVisualsを持たない():
		assert_null(balancer.get_node_or_null("ConveyorVisuals"))

	func test_BalancerはItemEjectorVisualを持つ():
		assert_not_null(balancer.get_node_or_null("ItemEjectorVisual"))

	func test_Balancerは保持アイテムのアイコンを表示する():
		balancer.add_item("iron_ore", 1)
		var visual = balancer.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_true(visual.get_node("ItemIcon").visible)

	func test_Balancerは保持なしならアイコン非表示():
		var visual = balancer.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_false(visual.get_node("ItemIcon").visible)

	func test_Balancerの保持アイテムは出力ポート側に飛び出る():
		# デフォルト出力は East(0)。スライドが進むとアイコンは中央ではなく +X 側に出る
		balancer.add_item("iron_ore", 1)
		balancer.get_node("ConveyorLogic").tick(0.4)  # スライドを進める(まだ排出しない)
		var visual = balancer.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_gt(visual.get_node("ItemIcon").position.x, 0.0)

	func test_Balancerの飛び出しアイテムは施設タイルより奥に描画される():
		# miner 同様、はみ出しアイテムは基礎タイルの背後から覗く（z が低い）
		var icon = balancer.get_node("ItemEjectorVisual/ItemIcon")
		var base_z = 0
		for child in balancer.get_children():
			if child is HexTile:
				base_z = child.z_index
		assert_lt(icon.z_index, base_z)
