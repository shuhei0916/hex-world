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
	bridge.tick(TransferBuffer.TRANSFER_TIME)
	assert_eq(target.get_item_count("iron_ore"), 1)


func test_接続先が不在ならアイテムを保持し続ける():
	bridge.add_item("iron_ore", 1)
	bridge.tick(TransferBuffer.TRANSFER_TIME)
	assert_eq(bridge.get_item_count("iron_ore"), 1)


func test_接続先を設定するとhas_connected_pieceがtrueになる():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target])
	assert_true(bridge.has_connected_piece())


func test_接続先がなければhas_connected_pieceはfalse():
	assert_false(bridge.has_connected_piece())


func _get_hex_tile(piece: Piece) -> PieceBody:
	return piece.get_node_or_null("Body")


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
	chunk.place_piece(BRIDGE_SCENE, Vector2i(-2, 1), 0)
	chunk.place_piece(preload("res://scenes/components/piece/conveyor.tscn"), Vector2i(-1, 1), 0)
	var placed_bridge = chunk.get_piece_at_hex(Vector2i(-2, 1))
	assert_eq(placed_bridge.get_connected_pieces(), [])


func test_渡した品目を毎分の個数で数える():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target])
	bridge.add_item("iron_ore", 1)
	bridge.tick(TransferBuffer.TRANSFER_TIME)
	# 2 秒で 1 個 → 毎分 30 個
	assert_eq(bridge.conveyor_logic.get_items_per_minute(), {"iron_ore": 30.0})


func test_渡せなかった品目は数えない():
	bridge.add_item("iron_ore", 1)
	bridge.tick(TransferBuffer.TRANSFER_TIME)
	assert_eq(bridge.conveyor_logic.get_items_per_minute(), {})


func test_コンベア高速化の研究で時計は速まらない():
	var target = BRIDGE_SCENE.instantiate()
	add_child_autofree(target)
	target.setup()
	bridge.set_connected_pieces([target])
	var saved = HubGoals.researched
	HubGoals.researched = {"belt_speed_1": true}
	bridge.add_item("iron_ore", 1)
	bridge.tick(TransferBuffer.TRANSFER_TIME / HubGoals.get_belt_speed())
	HubGoals.researched = saved
	# 1 秒で 1 個 → 毎分 60 個（研究で速めた時間で数えると 30 個になってしまう）
	assert_eq(bridge.conveyor_logic.get_items_per_minute(), {"iron_ore": 60.0})
