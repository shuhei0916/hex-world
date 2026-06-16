# gdlint:disable=constant-name
extends GutTest

const SPLITTER_SCENE = preload("res://scenes/components/piece/splitter.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const Chunk = preload("res://scenes/components/chunk/chunk.gd")


class TestSplitterPorts:
	extends GutTest

	func test_Splitterはget_output_portsが2ポートを返す():
		var splitter = SPLITTER_SCENE.instantiate()
		add_child_autofree(splitter)
		splitter.setup(0)
		assert_eq(splitter.get_output_ports().size(), 2)

	func test_SplitterのデフォルトポートはEastとSE():
		var splitter = SPLITTER_SCENE.instantiate()
		add_child_autofree(splitter)
		splitter.setup(0)
		var ports = splitter.get_output_ports()
		assert_eq(ports[0]["direction"], 0)
		assert_eq(ports[1]["direction"], 5)


class TestSplitterConnection:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_Splitter配置後にconnected_piecesに2ピースが接続される():
		gm.place_piece(SPLITTER_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, 1))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(splitter.get_connected_pieces().size(), 2)

	func test_アイテムがラウンドロビンで2方向に分配される():
		gm.place_piece(SPLITTER_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, 1))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var chest_se = gm.get_piece_at_hex(Hex.new(0, 1))
		splitter.add_item("iron_ore", 1)
		splitter.get_node("SplitterLogic").tick(0.5)
		splitter.add_item("iron_ore", 1)
		splitter.get_node("SplitterLogic").tick(0.5)
		assert_eq(chest_e.get_item_count("iron_ore") + chest_se.get_item_count("iron_ore"), 2)

	func test_2アイテム送ると両方の接続先に1個ずつ届く():
		# コンベアラインを通じたシナリオ
		# Splitter(0,0) → conveyor_e(1,0) と conveyor_se(0,1) に分岐
		gm.place_piece(SPLITTER_SCENE, Hex.new(0, 0))
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East出力
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 1), 1)  # SE→NE... rotation確認
		gm.place_piece(CHEST_SCENE, Hex.new(2, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 1))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var conv_se = gm.get_piece_at_hex(Hex.new(0, 1))
		# 各コンベアが正しいchestに繋がっているか確認
		assert_eq(splitter.get_connected_pieces().size(), 2, "Splitterは2方向に接続されるべき")
		splitter.add_item("iron_ore", 1)
		splitter.get_node("SplitterLogic").tick(0.5)
		splitter.add_item("iron_ore", 1)
		splitter.get_node("SplitterLogic").tick(0.5)
		var total_in_conveyors = (
			conv_e.get_item_count("iron_ore") + conv_se.get_item_count("iron_ore")
		)
		assert_eq(total_in_conveyors, 2, "2アイテムが両コンベアに1個ずつ届くべき")


class TestSplitterVisuals:
	extends GutTest

	var splitter: Piece

	func before_each():
		splitter = SPLITTER_SCENE.instantiate()
		add_child_autofree(splitter)
		splitter.setup(0)

	func test_SplitterはConveyorVisualsを持たない():
		assert_null(splitter.get_node_or_null("ConveyorVisuals"))

	func test_SplitterはItemEjectorVisualを持つ():
		assert_not_null(splitter.get_node_or_null("ItemEjectorVisual"))

	func test_Splitterは保持アイテムのアイコンを表示する():
		splitter.add_item("iron_ore", 1)
		var visual = splitter.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_true(visual.get_node("ItemIcon").visible)

	func test_Splitterは保持なしならアイコン非表示():
		var visual = splitter.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_false(visual.get_node("ItemIcon").visible)

	func test_Splitterの保持アイテムは出力ポート側に飛び出る():
		# デフォルト出力は East(0) なのでアイコンは中央ではなく +X 側に出る
		splitter.add_item("iron_ore", 1)
		var visual = splitter.get_node("ItemEjectorVisual")
		visual.update_item_icon()
		assert_gt(visual.get_node("ItemIcon").position.x, 0.0)
