# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/smelter.tscn")


class TestOutputInventory:
	extends GutTest

	var output

	func before_each():
		var piece = PIECE_SCENE.instantiate()
		add_child(piece)
		autofree(piece)
		output = piece.get_node("Output")

	# Output は $Inventory への委譲のみ。インベントリのロジック自体は
	# test_inventory.gd で網羅済みのため、ここでは委譲の配線だけを確認する。
	func test_add_itemは内部インベントリに委譲される():
		output.add_item("iron", 5)
		assert_eq(output.get_item_count("iron"), 5)


class TestOutputTransport:
	extends GutTest

	var source: Piece
	var target: Piece

	func before_each():
		source = PIECE_SCENE.instantiate()
		add_child(source)
		autofree(source)
		source.setup()

		target = PIECE_SCENE.instantiate()
		add_child(target)
		autofree(target)
		target.setup()

	func test_接続先のピースにアイテムが搬出される():
		source.output.set_connected_pieces([target])
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 0)

	func test_搬出後に接続先ピースのインベントリにアイテムが追加される():
		source.output.set_connected_pieces([target])
		source.output.add_item("iron", 1)
		assert_eq(target.get_item_count("iron"), 1)

	func test_接続先がない場合はアイテムが搬出されない():
		source.output.set_connected_pieces([])
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 1)

	func test_接続先が満杯の場合は移動しない():
		source.output.set_connected_pieces([target])
		target.add_item("junk", 1)  # 入力容量はレシピ1回分(1)なので1個で満杯
		source.output.add_item("iron", 1)
		assert_eq(source.output.get_item_count("iron"), 1)

	func test_接続先が後から空いたらtickで再送される():
		# バグ: 押せずに滞留したアイテムは、下流が空いても再送トリガーが無く詰まる
		source.output.set_connected_pieces([target])
		target.add_item("junk", 1)  # 接続先を満杯にする
		source.output.add_item("iron", 1)  # 押せずに滞留
		target.input_storage.consume_item("junk", 1)  # 接続先が空く（再送イベントは発生しない）
		source.output.tick(0.1)  # tick で再送を試みるべき
		assert_eq(source.output.get_item_count("iron"), 0)


class TestOutputRoundRobin:
	extends GutTest

	var source: Piece
	var target_a: Piece
	var target_b: Piece

	func before_each():
		source = PIECE_SCENE.instantiate()
		add_child(source)
		autofree(source)
		source.setup()
		target_a = PIECE_SCENE.instantiate()
		add_child(target_a)
		autofree(target_a)
		target_b = PIECE_SCENE.instantiate()
		add_child(target_b)
		autofree(target_b)
		source.output.set_connected_pieces([target_a, target_b])

	func test_1回目はtarget_aへ送られる():
		source.output.add_item("iron", 1)
		assert_eq(target_a.get_item_count("iron"), 1)
		assert_eq(target_b.get_item_count("iron"), 0)

	func test_2回目はtarget_bへ送られる():
		source.output.add_item("iron", 1)
		source.output.add_item("iron", 1)
		assert_eq(target_b.get_item_count("iron"), 1)

	func test_3回目はtarget_aへ戻る():
		source.output.add_item("iron", 1)
		source.output.add_item("iron", 1)
		source.output.add_item("iron", 1)
		assert_eq(target_a.get_item_count("iron"), 2)

	func test_2個まとめて追加すると両方の接続先に分配される():
		source.output.add_item("iron", 2)
		assert_eq(target_b.get_item_count("iron"), 1)
