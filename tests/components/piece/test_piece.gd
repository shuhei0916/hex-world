# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")


# --- 基本機能のテスト ---
class TestPieceBasics:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child_autofree(piece)

	func test_セットアップでタイプと座標を正しく設定できる():
		var dummy_type = PieceDB.PieceType.BAR
		var dummy_coords = [Hex.new(0, 0), Hex.new(1, 0)]
		var data = {"type": dummy_type, "hex_coordinates": dummy_coords}

		piece.setup(data)

		assert_eq(piece.piece_type, dummy_type)
		assert_eq(piece.hex_coordinates.size(), 2)

	func test_Pieceのインターフェース経由でアイテムを操作できる():
		piece.add_item("iron", 10)
		assert_eq(piece.get_item_count("iron"), 10)

	func test_インベントリが満杯の場合はアイテムを受け入れない():
		piece.add_item("iron", 20)
		assert_false(piece.can_accept_item("copper"), "満杯時は受け入れ拒否すべき")


# --- 視覚表現と連携のテスト ---
class TestPieceVisuals:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child_autofree(piece)

	func test_アイテム追加時に在庫表示ラベルが更新される():
		piece.setup({"type": PieceDB.PieceType.CHEST})
		piece.set_detail_mode(true)
		piece.add_item("iron_ore", 10)

		var label = piece.get_node("StatusIcon/CountLabel")
		assert_true(label.visible)
		assert_eq(label.text, "10")

	func test_ポートの描画用パラメータを正しく計算できる():
		var out_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test"
		)
		piece.setup({"type": -1}, out_data)
		var params = piece.get_port_visual_params()
		assert_eq(params.size(), 1)
		assert_almost_eq(params[0].rotation, 0.0, 0.01)


# --- 物流と接続のテスト（結合テスト） ---
class TestPieceLogistics:
	extends GutTest

	var grid_manager: GridManager
	var piece_a: Piece  # 送り側
	var piece_b: Piece  # 受け側 (Chest)

	func before_each():
		grid_manager = GridManager.new()
		grid_manager.hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
		add_child_autofree(grid_manager)
		grid_manager.create_hex_grid(3)

		# 共通セットアップ: A(0,0) -> B(1,0,-1) 方向0で接続
		var out_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test"
		)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, out_data)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0, -1), null, PieceDB.PieceType.CHEST)

		piece_a = grid_manager.get_piece_at_hex(Hex.new(0, 0))
		piece_b = grid_manager.get_piece_at_hex(Hex.new(1, 0, -1))

	func test_ポートが接続された隣接ピース間でアイテムが移動する():
		piece_a.add_to_output("iron", 1)
		assert_eq(piece_a.get_item_count("iron"), 0, "搬出元からは減るべき")
		assert_eq(piece_b.get_item_count("iron"), 1, "搬入先には増えるべき")

	func test_出力ポートが相手の方向を向いている場合のみ接続可能と判定される():
		assert_true(piece_a.can_push_to(piece_b, 0), "方向0に向いているポートは接続可能であるべき")

	func test_生産ライン全体の連携が正しく機能する():
		# シナリオテスト: 一旦クリアして独自のラインを組む
		grid_manager.clear_grid()
		grid_manager.create_hex_grid(3)

		var m_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "miner"
		)
		var s_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)

		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(0, 0), null, -1, 0, m_data)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(1, 0), null, -1, 0, s_data)
		grid_manager.place_piece([Hex.new(0, 0)], Hex.new(2, 0), null, PieceDB.PieceType.CHEST)

		var miner = grid_manager.get_piece_at_hex(Hex.new(0, 0))
		var smelter = grid_manager.get_piece_at_hex(Hex.new(1, 0))
		var chest = grid_manager.get_piece_at_hex(Hex.new(2, 0))

		miner.tick(1.1)
		assert_eq(smelter.get_item_count("iron_ore"), 1, "採掘機から炉へ移動するべき")

		smelter.tick(3.1)
		assert_eq(chest.get_item_count("iron_ingot"), 1, "炉からチェストへ移動するべき")


# --- 回転ロジックのテスト ---
class TestPieceTransformation:
	extends GutTest

	func test_ポートの向きはピースの回転に追従する():
		var p = Piece.new()
		var out_data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test"
		)
		p.setup({"type": -1}, out_data)
		add_child_autofree(p)

		assert_eq(p.get_output_ports()[0].direction, 0)
		p.rotate_cw()
		assert_eq(p.get_output_ports()[0].direction, 5)


# --- 特殊な役割を持つピースのテスト ---
class TestPieceRoles:
	extends GutTest

	func test_製錬所ロールは初期化時に自動的に適切なレシピとポートが設定される():
		var p = Piece.new()
		var data = PieceDB.PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)
		p.setup({"type": -1}, data)

		assert_not_null(p.current_recipe, "製錬所はレシピを持つべき")
		assert_gt(p.get_output_ports().size(), 0, "製錬所は出力ポートを持つべき")

	func test_採掘機ロールは時間経過でアイテムを自動生産する():
		var p = PIECE_SCENE.instantiate()
		var data = PieceDB.PieceData.new([Hex.new(0, 0)], [], "miner")
		p.setup({"type": -1}, data)
		add_child_autofree(p)

		p.tick(1.1)
		assert_eq(p.get_item_count("iron_ore"), 1)
