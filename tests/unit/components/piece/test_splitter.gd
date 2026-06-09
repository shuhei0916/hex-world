# gdlint:disable=constant-name
extends GutTest

const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
const Chunk = preload("res://scenes/components/chunk/chunk.gd")

# splitter.tscn が作成されるまでコンベアシーンをベースに手動でSplitter相当を設定する
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")


class TestSplitterPorts:
	extends GutTest

	func test_port_direction2を設定するとget_output_portsが2ポートを返す():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		piece.port_direction = 0  # East
		piece.port_direction2 = 5  # SE
		piece.setup(0)
		assert_eq(piece.get_output_ports().size(), 2)

	func test_2ポートの方向が正しい():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		piece.port_direction = 0  # East
		piece.port_direction2 = 5  # SE
		piece.setup(0)
		var ports = piece.get_output_ports()
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
		# Splitter相当: (0,0) に East(0) と SE(5) の2出力
		# 接続先: East→(1,0), SE→(0,1)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		splitter.port_direction2 = 5  # SE を追加
		gm.update_connections_around(splitter)
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, 1))
		assert_eq(splitter.output.connected_pieces.size(), 2)

	func test_アイテムがラウンドロビンで2方向に分配される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		var splitter = gm.get_piece_at_hex(Hex.new(0, 0))
		splitter.port_direction2 = 5
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(0, 1))
		gm.update_connections_around(splitter)
		var chest_e = gm.get_piece_at_hex(Hex.new(1, 0))
		var chest_se = gm.get_piece_at_hex(Hex.new(0, 1))
		splitter.add_item("iron_ore", 1)
		splitter.get_node("ConveyorLogic").tick(0.5)
		splitter.add_item("iron_ore", 1)
		splitter.get_node("ConveyorLogic").tick(0.5)
		assert_eq(chest_e.get_item_count("iron_ore") + chest_se.get_item_count("iron_ore"), 2)
