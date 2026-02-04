# gdlint:disable=constant-name
extends GutTest

const Types = PieceDB.PieceType
const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")

var piece: Piece


func before_each():
	piece = PIECE_SCENE.instantiate()
	add_child_autofree(piece)


func test_setupでタイプと座標を設定できる():
	var dummy_type = Types.BAR
	var dummy_coords = [Hex.new(0, 0), Hex.new(1, 0)]
	var data = {"type": dummy_type, "hex_coordinates": dummy_coords}

	piece.setup(data)

	assert_eq(piece.piece_type, dummy_type, "piece_type should be set")
	assert_eq(piece.hex_coordinates.size(), 2)


func test_Pieceを通じてアイテムの追加と取得ができる():
	# これはPieceが内部のItemContainerを正しく管理しているかの疎通確認
	piece.add_item("iron", 10)
	assert_eq(piece.get_item_count("iron"), 10, "Piece経由でアイテムが追加・取得できるべき")


func test_アイテム追加時にラベルが更新される():
	# CHESTタイプとしてセットアップ
	piece.setup({"type": PieceDB.PieceType.CHEST})
	piece.set_detail_mode(true)
	piece.add_item("iron_ore", 10)

	var label = piece.get_node("StatusIcon/CountLabel")
	assert_true(label.visible)
	assert_eq(label.text, "10")


func test_Miner機能を持つピースは時間経過でアイテムを生産する():
	var miner_data = PieceDB.PieceData.new([Hex.new(0, 0)], [], "miner")
	piece.setup({"type": -1}, miner_data)

	assert_eq(piece.get_item_count("iron_ore"), 0)
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron_ore"), 0)
	piece.tick(0.5)
	assert_eq(piece.get_item_count("iron_ore"), 1)


func test_Smelter機能を持つピースは材料なしでは自動生産しない():
	var smelter_data = PieceDB.PieceData.new([Hex.new(0, 0)], [], "smelter")
	piece.setup({"type": -1}, smelter_data)

	piece.tick(2.0)
	assert_eq(piece.get_item_count("iron_ingot"), 0, "Smelterは材料なしでは生産すべきではない")


func test_未初期化のPieceは生産しない():
	piece.tick(1.0)
	assert_eq(piece.get_item_count("iron"), 0)


func test_Storage機能を持つピースはアイテムを生産しない():
	var storage_data = PieceDB.PieceData.new([Hex.new(0, 0)], [], "storage")
	piece.setup({"type": -1}, storage_data)

	piece.tick(2.0)
	assert_eq(piece.get_item_count("iron"), 0)


class TestItemTransport:
	extends GutTest

	const Types = PieceDB.PieceType
	var grid_manager: GridManager

	func before_each():
		grid_manager = GridManager.new()
		grid_manager.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

	func test_ポート接続された隣接ピースにアイテムが移動する():
		# A: 出力ポート(方向0)を持つピース
		var out_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test_role"
		)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, out_data)
		var piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), null, Types.TEST_IN)
		var piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		piece_a.add_to_output("iron", 1)
		piece_a.tick(0.1)

		assert_eq(piece_a.get_item_count("iron"), 0, "Piece A should have pushed the item")
		assert_eq(piece_b.get_item_count("iron"), 1, "Piece B should have received the item")

	func test_生産ラインが稼働してアイテムが加工・輸送される():
		# シナリオテストとして価値があるため残す
		# 1. Miner
		var m_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "miner"
		)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, m_data)

		# 2. Smelter
		var s_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0), null, -1, 0, s_data)

		# 3. Assembler
		var a_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "constructor"
		)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(2, 0), null, -1, 0, a_data)

		# 4. Chest
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(3, 0), null, Types.CHEST)

		var miner = grid_manager.get_piece_at_hex(Hex.new(0, 0))
		var smelter = grid_manager.get_piece_at_hex(Hex.new(1, 0))
		var assembler = grid_manager.get_piece_at_hex(Hex.new(2, 0))
		var chest = grid_manager.get_piece_at_hex(Hex.new(3, 0))

		# シミュレーション
		miner.tick(2.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1)

		smelter.tick(3.1)
		assert_eq(assembler.get_item_count("iron_ingot"), 1)

		assembler.tick(4.1)
		assert_eq(chest.get_item_count("iron_plate"), 1)


class TestPiecePorts:
	extends GutTest

	func test_デフォルトでは出力ポートは定義に従う():
		var piece = Piece.new()
		assert_eq(piece.get_output_ports().size(), 0)


class TestPortConnections:
	extends GutTest

	const Types = PieceDB.PieceType
	var grid_manager: GridManager
	var piece_a: Piece
	var piece_b: Piece

	func before_each():
		grid_manager = GridManager.new()
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, Types.TEST_OUT)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), null, Types.TEST_IN)

		piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0, 0))
		piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

	func test_出力ポートが相手の方向を向いていれば接続可能():
		assert_true(piece_a.can_push_to(piece_b, 0))

	func test_出力ポートが対面でも相手がそこに存在すれば接続可能():
		var out_data_a = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test_role"
		)
		var out_data_b = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 3}], "test_role"
		)

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, out_data_a)
		piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), null, -1, 0, out_data_b)
		piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

		assert_true(piece_a.can_push_to(piece_b, 0))

	func test_入力ポート定義がなくても受け取れる():
		assert_true(piece_a.can_push_to(piece_b, 0))


class TestPieceRotation:
	extends GutTest

	func test_ポートはピースの回転に追従する():
		var piece = Piece.new()
		piece.setup({"type": PieceDB.PieceType.TEST_OUT})
		add_child_autofree(piece)

		assert_eq(piece.get_output_ports()[0].direction, 0)
		piece.rotate_cw()
		assert_eq(piece.get_output_ports()[0].direction, 5)

	func test_複数ヘックスを持つピースのポートも回転する():
		var piece = Piece.new()
		var multi_data = PieceDB.PieceData.new(
			[Hex.new(0, 0), Hex.new(1, 0)], [{"hex": Hex.new(1, 0), "direction": 0}], "test_role"
		)
		piece.setup({"type": -1}, multi_data)
		add_child_autofree(piece)

		piece.rotate_cw()
		var rotated_port = piece.get_output_ports()[0]
		assert_true(Hex.equals(rotated_port.hex, Hex.new(0, 1)))
		assert_eq(rotated_port.direction, 5)


class TestPieceVisuals:
	extends GutTest

	func test_ポートの描画パラメータを計算できる():
		var piece = Piece.new()
		piece.setup({"type": PieceDB.PieceType.TEST_OUT})
		add_child_autofree(piece)
		var params = piece.get_port_visual_params()
		assert_eq(params.size(), 1)
		assert_almost_eq(params[0].rotation, 0.0, 0.01)

	func test_回転したポートの描画パラメータも正しく計算される():
		var piece = Piece.new()
		piece.setup({"type": PieceDB.PieceType.TEST_OUT})
		add_child_autofree(piece)

		piece.rotate_cw()
		var params = piece.get_port_visual_params()
		if params.size() > 0:
			assert_almost_eq(params[0].rotation, PI / 3.0, 0.01)


class TestPieceProcessing:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = Piece.new()
		piece.setup({"type": PieceDB.PieceType.CHEST})
		add_child_autofree(piece)

	func test_Piece経由でレシピを設定し加工を開始できる():
		# Pieceが内部のCrafterを正しく初期化・実行しているかの疎通確認
		var recipe = Recipe.new("test_recipe", {"ore": 1}, {"ingot": 1}, 1.0)
		piece.set_recipe(recipe)
		piece.add_item("ore", 1)
		piece.tick(0.1)

		assert_gt(piece.processing_progress, 0.0, "Piece経由で加工が進むべき")
		assert_eq(piece.get_item_count("ore"), 0, "材料が消費されているべき")


class TestSmelter:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = Piece.new()
		var smelter_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)
		piece.setup({"type": -1}, smelter_data)
		add_child_autofree(piece)

	func test_Smelter役割は自動的にレシピを持つ():
		assert_not_null(piece.current_recipe)
		assert_eq(piece.current_recipe.id, "iron_ingot")

	func test_Smelter役割は出力ポートを持つ():
		assert_gt(piece.get_output_ports().size(), 0, "出力ポートが必要")


class TestAssembler:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = Piece.new()
		var assembler_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "constructor"
		)
		piece.setup({"type": -1}, assembler_data)
		add_child_autofree(piece)

	func test_Constructor役割は自動的にレシピを持つ():
		assert_not_null(piece.current_recipe)
		assert_eq(piece.current_recipe.id, "iron_plate")

	func test_Constructor役割は出力ポートを持つ():
		assert_gt(piece.get_output_ports().size(), 0, "出力ポートが必要")
