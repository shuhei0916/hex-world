# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")


class TestPieceBasics:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child_autofree(piece)

	func test_セットアップでデータを正しく設定できる():
		var data = PieceData.get_data(PieceData.Type.CONVEYOR)
		piece.setup(data)
		assert_eq(piece._cached_data.role, "conveyor")

	func test_add_itemでPieceにアイテムを追加できる():
		piece.setup(PieceData.get_data(PieceData.Type.CHEST))
		piece.add_item("iron", 10)
		assert_eq(piece.get_item_count("iron"), 10)

	func test_インベントリが満杯の場合はアイテムを受け入れない():
		piece.setup(PieceData.get_data(PieceData.Type.CHEST))
		piece.add_item("iron", 20)
		assert_false(piece.can_accept_item("copper"))


class TestPieceVisuals:
	extends GutTest

	var piece: Piece

	func before_each():
		piece = PIECE_SCENE.instantiate()
		add_child_autofree(piece)

	func test_出力ポートが存在する場合に矢印が表示される():
		var data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test_arrow"
		)
		piece.setup(data)

		var arrow = piece.get_node("OutputPort")
		assert_true(arrow.visible, "出力ポートがある場合、矢印が表示されるべき")


class TestPieceTransformation:
	extends GutTest
	var p: Piece

	func before_each():
		p = PIECE_SCENE.instantiate()
		p.setup(PieceData.get_data(PieceData.Type.ASSEMBLER))
		add_child_autofree(p)

	func test_ピースの回転に合わせてポートの向きも変更される():
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


class TestPieceRoles:
	extends GutTest

	func test_製錬所ロールは初期化時に自動的に適切なレシピとポートが設定される():
		var p = PIECE_SCENE.instantiate()
		add_child(p)
		autofree(p)
		var data = PieceData.new(
			[Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "smelter"
		)
		p.setup(data)

		assert_not_null(p.current_recipe, "製錬所はレシピを持つべき")
		assert_gt(p.get_output_ports().size(), 0, "製錬所は出力ポートを持つべき")

	func test_採掘機ロールは時間経過でアイテムを自動生産する():
		var p = PIECE_SCENE.instantiate()
		add_child(p)
		autofree(p)
		var data = PieceData.new([Hex.new(0, 0)], [], "miner")
		p.setup(data)

		p.tick(1.1)
		assert_eq(p.get_item_count("iron_ore"), 1)

	func test_Inputノードなしのピースでもcrafterがアイテムを生産できる():
		const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
		var p = MINER_SCENE.instantiate()
		add_child(p)
		autofree(p)
		p.setup(PieceData.get_data(PieceData.Type.MINER))

		p.tick(1.1)
		assert_eq(p.get_item_count("iron_ore"), 1)
