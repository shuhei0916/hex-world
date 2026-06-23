# gdlint:disable=constant-name
extends GutTest

const PIECE_SCENE = preload("res://scenes/components/piece/smelter.tscn")


# 容量無制限の受け入れスタブ（round-robin 分配ロジックを実ピースの容量から切り離して検証する）。
class StubTarget:
	extends Node
	var _counts := {}

	func can_accept_item(_item_name: String) -> bool:
		return true

	func add_item(item_name: String, amount: int) -> void:
		_counts[item_name] = _counts.get(item_name, 0) + amount

	func get_item_count(item_name: String) -> int:
		return _counts.get(item_name, 0)


class TestEjectorSlot:
	extends GutTest

	var output

	func before_each():
		var piece = PIECE_SCENE.instantiate()
		add_child(piece)
		autofree(piece)
		output = piece.get_node("ItemEjector")

	# ItemEjector は内部スロット(_item/_count)でアイテムを保持する。
	func test_add_itemで内部スロットにアイテムが保持される():
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
		source.ejector.set_connected_pieces([target])
		source.ejector.add_item("iron_ore", 1)
		source.ejector.tick(1.0)  # スライド完了させて排出
		assert_eq(source.ejector.get_item_count("iron_ore"), 0)

	func test_搬出後に接続先ピースのインベントリにアイテムが追加される():
		source.ejector.set_connected_pieces([target])
		source.ejector.add_item("iron_ore", 1)
		source.ejector.tick(1.0)
		assert_eq(target.get_item_count("iron_ore"), 1)

	func test_接続先がない場合はアイテムが搬出されない():
		source.ejector.set_connected_pieces([])
		source.ejector.add_item("iron_ore", 1)
		assert_eq(source.ejector.get_item_count("iron_ore"), 1)

	func test_接続先が満杯の場合は移動しない():
		source.ejector.set_connected_pieces([target])
		target.add_item("iron_ore", 1)  # 入力容量はレシピ1回分(1)なので1個で満杯
		source.ejector.add_item("iron_ore", 1)
		assert_eq(source.ejector.get_item_count("iron_ore"), 1)

	func test_接続先が後から空いたらtickで再送される():
		# バグ: 押せずに滞留したアイテムは、下流が空いても再送トリガーが無く詰まる
		source.ejector.set_connected_pieces([target])
		target.add_item("iron_ore", 1)  # 接続先を満杯にする
		source.ejector.add_item("iron_ore", 1)  # 押せずに滞留
		target.get_acceptor().consume_item("iron_ore", 1)  # 接続先が空く（再送イベントは発生しない）
		source.ejector.tick(1.0)  # tick でスライド完了＋再送を試みるべき
		assert_eq(source.ejector.get_item_count("iron_ore"), 0)


class TestOutputRoundRobin:
	extends GutTest

	var source: Piece
	var target_a
	var target_b

	func before_each():
		source = PIECE_SCENE.instantiate()
		add_child(source)
		autofree(source)
		source.setup()
		target_a = StubTarget.new()
		add_child(target_a)
		autofree(target_a)
		target_b = StubTarget.new()
		add_child(target_b)
		autofree(target_b)
		source.ejector.set_connected_pieces([target_a, target_b])

	# 各アイテムは add_item 後に tick(1.0) でスライド完了→排出される。
	func _eject_one(item_name: String):
		source.ejector.add_item(item_name, 1)
		source.ejector.tick(1.0)

	func test_1回目はtarget_aへ送られる():
		_eject_one("iron")
		assert_eq(target_a.get_item_count("iron"), 1)
		assert_eq(target_b.get_item_count("iron"), 0)

	func test_2回目はtarget_bへ送られる():
		_eject_one("iron")
		_eject_one("iron")
		assert_eq(target_b.get_item_count("iron"), 1)

	func test_3回目はtarget_aへ戻る():
		_eject_one("iron")
		_eject_one("iron")
		_eject_one("iron")
		assert_eq(target_a.get_item_count("iron"), 2)

	func test_2個まとめて追加すると両方の接続先に分配される():
		source.ejector.add_item("iron", 2)
		source.ejector.tick(1.0)  # 1個目スライド→排出(a)
		source.ejector.tick(1.0)  # 2個目スライド→排出(b)
		assert_eq(target_b.get_item_count("iron"), 1)
