extends GutTest

const RECEIVER_SCENE = preload("res://scenes/components/piece/receiver.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")


func test_アイテムを受け入れて保持する():
	var receiver = RECEIVER_SCENE.instantiate()
	add_child_autofree(receiver)
	receiver.setup()
	receiver.add_item("iron_ore", 1)
	assert_eq(receiver.get_item_count("iron_ore"), 1)


func test_チャンク内の下流コンベアへ既存配線で搬出される():
	var chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(2)
	# 東(0)向きの Receiver とその先のコンベアを設置すると NeighborManager が配線する
	chunk.place_piece(RECEIVER_SCENE, Hex.new(-2, 1, 1), 0)
	chunk.place_piece(CONVEYOR_SCENE, Hex.new(-1, 1, 0), 0)
	var receiver = chunk.get_piece_at_hex(Hex.new(-2, 1, 1))
	var conveyor = chunk.get_piece_at_hex(Hex.new(-1, 1, 0))
	receiver.add_item("iron_ore", 1)
	receiver.tick(1.0)
	assert_eq(conveyor.get_item_count("iron_ore"), 1)
