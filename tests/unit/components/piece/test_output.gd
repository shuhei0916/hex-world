# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/piece.tscn")


class TestOutputInventory:
	extends GutTest

	var output

	func before_each():
		var piece = PIECE_SCENE.instantiate()
		add_child(piece)
		autofree(piece)
		output = piece.get_node("Output")

	func test_初期状態のインベントリは空である():
		assert_eq(output.get_item_count("iron"), 0)

	func test_アイテムを追加すると数が加算される():
		output.add_item("iron", 5)
		assert_eq(output.get_item_count("iron"), 5)

	func test_アイテムを消費できる():
		output.add_item("iron", 5)
		output.consume_item("iron", 2)
		assert_eq(output.get_item_count("iron"), 3)

	func test_合計アイテム数を取得できる():
		output.add_item("iron", 5)
		output.add_item("copper", 3)
		assert_eq(output.get_total_item_count(), 8)

	func test_満杯状態を正しく判定できる():
		output.add_item("junk", 20)
		assert_true(output.is_full())

	func test_空状態を正しく判定できる():
		assert_true(output.is_empty())

	func test_アイテム追加後は空でない():
		output.add_item("iron", 1)
		assert_false(output.is_empty())


class TestOutputTransport:
	extends GutTest

	var source: Piece
	var target: Piece

	func before_each():
		source = PIECE_SCENE.instantiate()
		add_child(source)
		autofree(source)
		source.setup(PieceData.new([Hex.new(0, 0)], [], "miner"))

		target = PIECE_SCENE.instantiate()
		add_child(target)
		autofree(target)
		target.setup(PieceData.get_data(PieceData.Type.CHEST))

	func test_接続先のピースにアイテムが搬出される():
		source.output.connected_pieces = [target]
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 0)

	func test_搬出後に接続先ピースのインベントリにアイテムが追加される():
		source.output.connected_pieces = [target]
		source.output.add_item("iron", 1)
		assert_eq(target.get_item_count("iron"), 1)

	func test_接続先がない場合はアイテムが搬出されない():
		source.output.connected_pieces = []
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 1)

	func test_接続先が満杯の場合は移動しない():
		source.output.connected_pieces = [target]
		target.add_item("junk", 20)
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 1)
