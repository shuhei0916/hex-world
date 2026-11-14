extends GutTest

## 橋: chunk の辺に置き、溝の向こうの隣の chunk の向かいのマスへアイテムを渡す施設

const BRIDGE_SCENE = preload("res://scenes/components/piece/bridge.tscn")

var bridge: Piece


func before_each():
	bridge = BRIDGE_SCENE.instantiate()
	add_child_autofree(bridge)
	bridge.setup()


func test_アイテムを受け入れて保持する():
	bridge.add_item("iron_ore", 1)
	assert_eq(bridge.get_item_count("iron_ore"), 1)


func test_接続した相手へtickでアイテムを渡す():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target])
	bridge.add_item("iron_ore", 1)
	bridge.tick(1.0)
	assert_eq(target.get_item_count("iron_ore"), 1)


func test_接続先が不在ならアイテムを保持し続ける():
	bridge.add_item("iron_ore", 1)
	bridge.tick(1.0)
	assert_eq(bridge.get_item_count("iron_ore"), 1)


func test_接続先を設定するとhas_connected_pieceがtrueになる():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target])
	assert_true(bridge.has_connected_piece())


func test_接続先がなければhas_connected_pieceはfalse():
	assert_false(bridge.has_connected_piece())


func _get_hex_tile(piece: Piece) -> HexTile:
	for child in piece.get_children():
		if child is HexTile:
			return child
	return null


func test_接続時にヘックスタイルのmodulateが変わる():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	var before = _get_hex_tile(bridge).modulate
	bridge.set_connected_pieces([target])
	assert_ne(_get_hex_tile(bridge).modulate, before)


func test_接続解除でヘックスタイルのmodulateが元に戻る():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	var before = _get_hex_tile(bridge).modulate
	bridge.set_connected_pieces([target])
	bridge.set_connected_pieces([])
	assert_eq(_get_hex_tile(bridge).modulate, before)


func test_向きの矢印は施設には付けない_溝の上の帯で示す():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target], [5])
	assert_null(bridge.get_node_or_null("ConnectionArrow"))


func test_チャンク内の隣接ピースへは自動配線されない():
	var chunk = Chunk.new()
	add_child_autofree(chunk)
	chunk.create_hex_grid(2)
	chunk.place_piece(BRIDGE_SCENE, Hex.new(-2, 1, 1), 0)
	chunk.place_piece(preload("res://scenes/components/piece/conveyor.tscn"), Hex.new(-1, 1, 0), 0)
	var placed_bridge = chunk.get_piece_at_hex(Hex.new(-2, 1, 1))
	assert_eq(placed_bridge.get_connected_pieces(), [])
