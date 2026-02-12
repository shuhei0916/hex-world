# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")


class TestPieceUnit:
	extends GutTest

	var source: Piece
	var target: Piece

	func before_each():
		source = Piece.new()
		source.setup({"type": -1})
		add_child_autofree(source)

		target = Piece.new()
		target.setup({"type": PieceDB.PieceType.CHEST})
		add_child_autofree(target)

	func test_接続先のピースにアイテムが搬出される():
		source.destinations = [target]
		source.add_to_output("iron", 1)
		source._push_items()
		assert_eq(source.get_item_count("iron"), 0)
		assert_eq(target.get_item_count("iron"), 1)

	func test_接続先がない場合はアイテムが搬出されない():
		source.destinations = []
		source.add_to_output("iron", 1)
		source._push_items()
		assert_eq(source.get_item_count("iron"), 1)
		assert_eq(target.get_item_count("iron"), 0)


# --- シーン構成と連携のテスト (コンポーネントテスト) ---
class TestPieceBasics:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child_autofree(piece)

	func test_セットアップでタイプを正しく設定できる():
		var dummy_type = PieceDB.PieceType.BAR
		var data = {"type": PieceDB.PieceType.BAR}

		piece.setup(data)

		assert_eq(piece.piece_type, dummy_type)

	func test_add_itemでPieceにアイテムを追加できる():
		piece.add_item("iron", 10)
		assert_eq(piece.get_item_count("iron"), 10)

	func test_インベントリが満杯の場合はアイテムを受け入れない():
		piece.add_item("iron", 20)
		assert_false(piece.can_accept_item("copper"))


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


# --- 回転ロジックのテスト ---
class TestPieceTransformation:
	extends GutTest
	var p: Piece

	func before_each():
		p = Piece.new()
		p.setup({"type": PieceDB.PieceType.WAVE})
		add_child_autofree(p)

	func test_ポートの向きはピースの回転に追従する():
		assert_eq(p.get_output_ports()[0].direction, 2)
		p.rotate_cw()
		assert_eq(p.get_output_ports()[0].direction, 1)

	func test_回転前のピースの形状を取得できる():
		var result = p.get_hex_shape()
		assert_eq(result.size(), 4)
		assert_true(Hex.equals(result[0], Hex.new(-1, 0, 1)))
		assert_true(Hex.equals(result[1], Hex.new(0, 0, 0)))

	func test_回転後のピースの形状を取得できる():
		p.rotate_cw()
		var result = p.get_hex_shape()
		assert_true(Hex.equals(result[0], Hex.new(0, -1, 1)))


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
		var p = Piece.new()
		var data = PieceDB.PieceData.new([Hex.new(0, 0)], [], "miner")
		p.setup({"type": -1}, data)
		add_child_autofree(p)

		p.tick(1.1)
		assert_eq(p.get_item_count("iron_ore"), 1)
