# gdlint:disable=constant-name
extends GutTest

const SPLITTER_SCENE = preload("res://scenes/components/piece/splitter.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
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
		assert_eq(splitter.output.connected_pieces.size(), 2)

	func test_アイテムがラウンドロビンで2方向に分配される():
		gm.place_piece(SPLITTER_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, 1))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var chest_se = gm.get_piece_at_hex(Hex.new(0, 1))
		splitter.add_item("iron_ore", 1)
		splitter.get_node("ConveyorLogic").tick(0.5)
		splitter.add_item("iron_ore", 1)
		splitter.get_node("ConveyorLogic").tick(0.5)
		assert_eq(chest_e.get_item_count("iron_ore") + chest_se.get_item_count("iron_ore"), 2)
