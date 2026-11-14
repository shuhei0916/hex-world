extends GutTest

## chunk チェスト: 同じ chunk の中で中身を共有する。入れる用（搬入）と取り出す用（搬出）は別のピース。

const CHEST_IN = preload("res://scenes/components/piece/chest_in.tscn")
const CHEST_OUT = preload("res://scenes/components/piece/chest_out.tscn")
const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")

var chunk: Chunk


func before_each():
	chunk = Chunk.new()
	add_child_autofree(chunk)


func _place(scene: PackedScene, hex: Hex, rotation: int = 0) -> Piece:
	chunk.place_piece(scene, hex, rotation)
	return chunk.get_piece_at_hex(hex)


func _tick_all(seconds: float) -> void:
	for i in int(seconds * 10):
		for piece in chunk.get_all_pieces():
			piece.tick(0.1)


class TestChestIn:
	extends "res://tests/unit/components/piece/test_chest.gd"

	func test_搬入チェストに入れたアイテムはchunkの共有在庫に入る():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		chest.add_item("iron_ore", 1)
		assert_eq(chunk.storage.get_count("iron_ore"), 1)

	func test_搬入チェストはどのアイテムも受け入れる():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		assert_true(chest.can_accept_item("iron_ore"))
		assert_true(chest.can_accept_item("coal"))

	func test_共有在庫が上限のアイテムは受け入れない():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		chunk.storage.add("iron_ore", SharedStorage.CAPACITY_PER_ITEM)
		assert_false(chest.can_accept_item("iron_ore"))
		assert_true(chest.can_accept_item("coal"))

	func test_コンベアから搬入チェストへアイテムが流れ込む():
		var conveyor = _place(CONVEYOR, Hex.new(0, 0))
		_place(CHEST_IN, Hex.new(1, 0))
		conveyor.add_item("iron_ore", 1)
		_tick_all(2.0)
		assert_eq(chunk.storage.get_count("iron_ore"), 1)
		assert_eq(conveyor.get_item_count("iron_ore"), 0)

	func test_搬入チェストは出力ポートを持たない():
		var chest = _place(CHEST_IN, Hex.new(0, 0))
		assert_eq(chest.get_output_ports(), [])

	func test_別のchunkの共有在庫には入らない():
		var other = Chunk.new()
		add_child_autofree(other)
		_place(CHEST_IN, Hex.new(0, 0)).add_item("iron_ore", 1)
		assert_eq(other.storage.get_count("iron_ore"), 0)


class TestChestOut:
	extends "res://tests/unit/components/piece/test_chest.gd"

	func _output_of(chest: Piece) -> Node:
		return chest.get_node("ChestOutput")

	func test_取り出すアイテムを選んでいない搬出チェストは何も出さない():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		chunk.storage.add("iron_ore", 5)
		_tick_all(2.0)
		assert_eq(chunk.storage.get_count("iron_ore"), 5)

	func test_選んだアイテムを共有在庫から取り出して隣のコンベアへ流す():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		var conveyor = _place(CONVEYOR, Hex.new(1, 0))
		assert_true(conveyor in chest.get_connected_pieces(), "前提: 搬出先につながっている")
		chunk.storage.add("iron_ore", 5)
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(1.0)
		assert_lt(chunk.storage.get_count("iron_ore"), 5)
		assert_eq(conveyor.get_item_count("iron_ore"), 1)

	func test_選んでいないアイテムは取り出さない():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		_place(CONVEYOR, Hex.new(1, 0))
		chunk.storage.add("coal", 5)
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(2.0)
		assert_eq(chunk.storage.get_count("coal"), 5)

	func test_搬出先が無いときは手元の1個までしか取り出さない():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		chunk.storage.add("iron_ore", 5)
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(5.0)
		assert_eq(chunk.storage.get_count("iron_ore"), 4)

	func test_搬出チェストはアイテムを受け入れない():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		assert_false(chest.can_accept_item("iron_ore"))

	func test_後から置いたチェストでも先に入れてあったアイテムを取り出せる():
		_place(CHEST_IN, Hex.new(-2, 0)).add_item("iron_ore", 3)
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		var conveyor = _place(CONVEYOR, Hex.new(1, 0))
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(1.0)
		assert_eq(conveyor.get_item_count("iron_ore"), 1)

	func test_搬出チェストを撤去すると手元に取り出していた1個は共有在庫へ戻る():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		chunk.storage.add("iron_ore", 5)
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(1.0)
		chunk.remove_piece_at(Hex.new(0, 0))
		assert_eq(chunk.storage.get_count("iron_ore"), 5)

	func test_取り出すアイテムを選び直すと手元の1個は共有在庫へ戻る():
		var chest = _place(CHEST_OUT, Hex.new(0, 0))
		chunk.storage.add("iron_ore", 5)
		chunk.storage.add("coal", 5)
		_output_of(chest).selected_item = "iron_ore"
		_tick_all(1.0)
		_output_of(chest).select_item("coal")
		assert_eq(chunk.storage.get_count("iron_ore"), 5)
		_tick_all(1.0)
		assert_eq(chunk.storage.get_count("coal"), 4)


class TestEndToEnd:
	extends "res://tests/unit/components/piece/test_chest.gd"

	func test_離れた場所の搬入チェストから搬出チェストへコンベア無しでアイテムが渡る():
		var feeder = _place(CONVEYOR, Hex.new(-4, 0))
		_place(CHEST_IN, Hex.new(-3, 0))
		var chest_out = _place(CHEST_OUT, Hex.new(2, 0))
		var receiver = _place(CONVEYOR, Hex.new(3, 0))
		chest_out.get_node("ChestOutput").selected_item = "iron_ore"
		feeder.add_item("iron_ore", 1)
		_tick_all(4.0)
		assert_eq(receiver.get_item_count("iron_ore"), 1)
