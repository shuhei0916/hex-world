extends GutTest

const SENDER_SCENE = preload("res://scenes/components/piece/sender.tscn")

var sender: Piece


func before_each():
	sender = SENDER_SCENE.instantiate()
	add_child_autofree(sender)
	sender.setup()


func test_アイテムを受け入れて保持する():
	sender.add_item("iron_ore", 1)
	assert_eq(sender.get_item_count("iron_ore"), 1)


func test_接続した相手へtickでアイテムを渡す():
	var receiver = SENDER_SCENE.instantiate()
	add_child_autofree(receiver)
	receiver.setup()
	sender.set_connected_pieces([receiver])
	sender.add_item("iron_ore", 1)
	sender.tick(1.0)
	assert_eq(receiver.get_item_count("iron_ore"), 1)


func test_接続先が不在ならアイテムを保持し続ける():
	sender.add_item("iron_ore", 1)
	sender.tick(1.0)
	assert_eq(sender.get_item_count("iron_ore"), 1)


func test_接続先を設定するとhas_connected_pieceがtrueになる():
	var receiver = SENDER_SCENE.instantiate()
	add_child_autofree(receiver)
	receiver.setup()
	sender.set_connected_pieces([receiver])
	assert_true(sender.has_connected_piece())


func test_接続先がなければhas_connected_pieceはfalse():
	assert_false(sender.has_connected_piece())


func test_接続時にmodulateが変わる():
	var receiver = SENDER_SCENE.instantiate()
	add_child_autofree(receiver)
	receiver.setup()
	var before = sender.modulate
	sender.set_connected_pieces([receiver])
	assert_ne(sender.modulate, before)


func test_接続解除でmodulateが元に戻る():
	var receiver = SENDER_SCENE.instantiate()
	add_child_autofree(receiver)
	receiver.setup()
	var before = sender.modulate
	sender.set_connected_pieces([receiver])
	sender.set_connected_pieces([])
	assert_eq(sender.modulate, before)


func test_チャンク内の隣接ピースへは自動配線されない():
	var chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(2)
	chunk.place_piece(SENDER_SCENE, Hex.new(-2, 1, 1), 0)
	chunk.place_piece(preload("res://scenes/components/piece/conveyor.tscn"), Hex.new(-1, 1, 0), 0)
	var placed_sender = chunk.get_piece_at_hex(Hex.new(-2, 1, 1))
	assert_eq(placed_sender.get_connected_pieces(), [])
