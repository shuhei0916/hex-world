# gdlint:disable=constant-name
extends GutTest

const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const CHEST_SCENE = preload("res://scenes/components/piece/chest.tscn")
const Chunk = preload("res://scenes/components/chunk/chunk.gd")


class TestConveyorShape:
	extends GutTest

	func test_conveyorは1ヘックス形状である():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_eq(piece.piece_shape.size(), 1)

	func test_conveyorのルートはConveyor型である():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_true(piece is Conveyor)

	func test_conveyorはInputノードを持つ():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_not_null(piece.get_node_or_null("Input"))

	func test_conveyorはOutputノードを持つ():
		var piece = CONVEYOR_SCENE.instantiate()
		add_child_autofree(piece)
		assert_not_null(piece.get_node_or_null("Output"))


class TestConveyorLogic:
	extends GutTest

	var conveyor

	func before_each():
		conveyor = CONVEYOR_SCENE.instantiate()
		add_child_autofree(conveyor)
		conveyor.setup()

	func test_add_itemするとInputインベントリに格納される():
		conveyor.add_item("iron_plate", 1)
		assert_eq(conveyor.input_storage.get_item_count("iron_plate"), 1)

	func test_アイテム保持中はcan_accept_itemがfalseを返す():
		conveyor.add_item("iron_plate", 1)
		assert_false(conveyor.can_accept_item("iron_plate"))

	func test_tick_0_4秒ではアイテムはOutputに転送されない():
		conveyor.add_item("iron_plate", 1)
		var logic = conveyor.get_node("ConveyorLogic")
		logic.tick(0.4)
		assert_eq(conveyor.output.get_item_count("iron_plate"), 0)

	func test_tick_0_5秒でアイテムがOutputに転送される():
		conveyor.add_item("iron_plate", 1)
		var logic = conveyor.get_node("ConveyorLogic")
		logic.tick(0.5)
		assert_eq(conveyor.output.get_item_count("iron_plate"), 1)

	func test_転送後はInputインベントリが空になる():
		conveyor.add_item("iron_plate", 1)
		var logic = conveyor.get_node("ConveyorLogic")
		logic.tick(0.5)
		assert_eq(conveyor.input_storage.get_item_count("iron_plate"), 0)


class TestConveyorConnection:
	extends GutTest

	var gm

	func before_each():
		gm = Chunk.new()
		add_child_autofree(gm)
		gm.create_hex_grid(3)

	func test_出力ポートの先のピースに接続される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		assert_true(chest in conveyor.output.connected_pieces)

	func test_Outputから接続先ピースへアイテムが搬出される():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		gm.place_piece(CHEST_SCENE, Hex.new(1, 0))
		var conveyor = gm.get_piece_at_hex(Hex.new(0, 0))
		var chest = gm.get_piece_at_hex(Hex.new(1, 0))
		conveyor.add_item("iron_plate", 1)
		conveyor.get_node("ConveyorLogic").tick(0.5)
		assert_eq(chest.get_item_count("iron_plate"), 1)

	func test_接続先が受け入れ不可の間アイテムは保持されたまま消えない():
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East → (1,0)
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East → (2,0)
		var conv_a = gm.get_piece_at_hex(Hex.new(0, 0))
		var conv_b = gm.get_piece_at_hex(Hex.new(1, 0))
		conv_b.add_item("iron_plate", 1)
		conv_a.add_item("iron_plate", 1)
		conv_a.get_node("ConveyorLogic").tick(0.5)
		assert_eq(conv_a.get_item_count("iron_plate"), 1)

	func test_曲がり角コンベアの入力エッジが実際の入力方向を向く():
		# (0,0)[East出力] → (1,0)[NW出力=rotation4] → (1,-1) のチェーン
		# (1,0)のコンベアは West(3) 側から入力を受け取るべき
		gm.place_piece(CONVEYOR_SCENE, Hex.new(0, 0), 0)  # East 方向
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 4)  # NW 方向
		gm.place_piece(CONVEYOR_SCENE, Hex.new(1, -1), 0)  # East 方向（接続先）
		var bend = gm.get_piece_at_hex(Hex.new(1, 0))
		var layout = Layout.make_default()
		var in_edge = bend._conveyor_line.get_point_position(0)
		var expected = Layout.hex_to_pixel(layout, Hex.hex_directions[3]) * 0.5
		assert_almost_eq(in_edge.x, expected.x, 0.1)
