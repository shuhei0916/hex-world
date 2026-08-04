# gdlint:disable=duplicated-load
extends GutTest

const World = preload("res://scenes/components/world/world.gd")


class TestChunkWiring:
	extends GutTest

	const SENDER_SCENE = preload("res://scenes/components/piece/sender.tscn")
	const RECEIVER_SCENE = preload("res://scenes/components/piece/receiver.tscn")

	# SE(5)の辺ヘックスとその点対称位置(pointy⇔flatのズレ補正によりworldmap上の東隣(1,0)に接続)
	const SENDER_HEX_QRS = [1, 1, -2]

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Hex.new(0, 0))
		chunk_b = world.create_chunk(Hex.new(1, 0))  # 東隣
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)

	func _sender_hex() -> Hex:
		return Hex.new(1, 1, -2)

	func _receiver_hex() -> Hex:
		return Hex.new(-1, -1, 2)

	func test_Receiverを後置きするとSenderが配線される():
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		chunk_b.place_piece(RECEIVER_SCENE, _receiver_hex())
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		var receiver = chunk_b.get_piece_at_hex(_receiver_hex())
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_Receiverが先にあってもSender設置時に配線される():
		chunk_b.place_piece(RECEIVER_SCENE, _receiver_hex())
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		var receiver = chunk_b.get_piece_at_hex(_receiver_hex())
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_Receiver不在なら配線されない():
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		assert_eq(sender.get_connected_pieces(), [])

	func test_点対称位置以外のReceiverには配線されない():
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-2, 0, 2))  # ずれた位置
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		assert_eq(sender.get_connected_pieces(), [])

	func test_Receiver撤去で配線が解除される():
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		chunk_b.place_piece(RECEIVER_SCENE, _receiver_hex())
		chunk_b.remove_piece_at(_receiver_hex())
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		assert_eq(sender.get_connected_pieces(), [])

	func test_南東チャンクへも点対称位置で配線される():
		var chunk_c = world.create_chunk(Hex.new(0, 1))  # 南東隣
		chunk_c.create_hex_grid(2)
		# r=R の辺（W(4)の辺、pointy⇔flat補正でworldmap上のSE(5)=南東隣へ接続）
		chunk_a.place_piece(SENDER_SCENE, Hex.new(-1, 2, -1))
		chunk_c.place_piece(RECEIVER_SCENE, Hex.new(1, -2, 1))
		var sender = chunk_a.get_piece_at_hex(Hex.new(-1, 2, -1))
		var receiver = chunk_c.get_piece_at_hex(Hex.new(1, -2, 1))
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_辺方向とworldmap上の隣接方向のズレを補正して配線される():
		# chunk(0,0)のhex(3,2)(s=-5, SEの辺)は、worldmap(flat-top)上では
		# (1,0)方向に隣接する(pointy⇔flatの角度ズレによりedge_dir+1が真の隣接方向)。
		# 辺内の対応位置は単純な原点対称ではなくq,rを入れ替えた(-2,-3,5)。
		chunk_a.grid_radius = 5
		chunk_b.grid_radius = 5
		chunk_a.place_piece(SENDER_SCENE, Hex.new(3, 2, -5))
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-2, -3, 5))
		var sender = chunk_a.get_piece_at_hex(Hex.new(3, 2, -5))
		var receiver = chunk_b.get_piece_at_hex(Hex.new(-2, -3, 5))
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_点対称位置ではなく辺内の対応位置に配線される():
		# chunk(0,0)のhex(4,1,-5)(SEの辺、q=radius寄りの端)は、
		# 単純な原点対称(-4,-1,5)ではなく、辺内で対応する位置(-1,-4,5)に配線される。
		chunk_a.grid_radius = 5
		chunk_b.grid_radius = 5
		chunk_a.place_piece(SENDER_SCENE, Hex.new(4, 1, -5))
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-1, -4, 5))
		var sender = chunk_a.get_piece_at_hex(Hex.new(4, 1, -5))
		var receiver = chunk_b.get_piece_at_hex(Hex.new(-1, -4, 5))
		assert_eq(sender.get_connected_pieces(), [receiver])

	func test_非アクティブチャンクのReceiverへアイテムが届く():
		world.set_active_chunk(Hex.new(0, 0))  # chunk_b は非表示のまま
		chunk_a.place_piece(SENDER_SCENE, _sender_hex())
		chunk_b.place_piece(RECEIVER_SCENE, _receiver_hex())
		var sender = chunk_a.get_piece_at_hex(_sender_hex())
		var receiver = chunk_b.get_piece_at_hex(_receiver_hex())
		sender.add_item("iron_ore", 1)
		sender.tick(1.0)
		assert_eq(receiver.get_item_count("iron_ore"), 1)


class TestReceiverHints:
	extends GutTest

	const SENDER_SCENE = preload("res://scenes/components/piece/sender.tscn")
	const RECEIVER_SCENE = preload("res://scenes/components/piece/receiver.tscn")

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Hex.new(0, 0))
		chunk_b = world.create_chunk(Hex.new(1, 0))  # 東隣
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)

	func test_隣接チャンクのSenderの点対称位置が受信候補になる():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		var hints = world.get_receiver_hint_hexes(Hex.new(1, 0))
		assert_eq(hints.map(Hex.to_key), [Hex.to_key(Hex.new(-1, -1, 2))])

	func test_アクティブチャンク切替でヒントがハイライトされる():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		world.set_active_chunk(Hex.new(1, 0))
		assert_true(chunk_b.find_hex_tile(Hex.new(-1, -1, 2)).is_highlighted)

	func test_Sender撤去でアクティブチャンクのヒントが消える():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		world.set_active_chunk(Hex.new(1, 0))
		chunk_a.remove_piece_at(Hex.new(1, 1, -2))
		assert_false(chunk_b.find_hex_tile(Hex.new(-1, -1, 2)).is_highlighted)

	func test_Receiver設置済みの位置は候補から除外される():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-1, -1, 2))
		var hints = world.get_receiver_hint_hexes(Hex.new(1, 0))
		assert_eq(hints, [])


class TestConnectedChunkPairs:
	extends GutTest

	const SENDER_SCENE = preload("res://scenes/components/piece/sender.tscn")
	const RECEIVER_SCENE = preload("res://scenes/components/piece/receiver.tscn")

	var world
	var chunk_a: Chunk
	var chunk_b: Chunk

	func before_each():
		world = World.new()
		add_child_autofree(world)
		chunk_a = world.create_chunk(Hex.new(0, 0))
		chunk_b = world.create_chunk(Hex.new(1, 0))  # 東隣
		chunk_a.create_hex_grid(2)
		chunk_b.create_hex_grid(2)

	func test_接続済みのSenderがあるチャンクペアを返す():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-1, -1, 2))
		var pairs = world.get_connected_chunk_pairs()
		assert_eq(pairs.size(), 1)
		assert_eq(Hex.to_key(pairs[0][0]), Hex.to_key(Hex.new(0, 0)))
		assert_eq(Hex.to_key(pairs[0][1]), Hex.to_key(Hex.new(1, 0)))

	func test_未接続なら空になる():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		var pairs = world.get_connected_chunk_pairs()
		assert_eq(pairs, [])

	func test_Sender撤去で対象ペアが消える():
		chunk_a.place_piece(SENDER_SCENE, Hex.new(1, 1, -2))
		chunk_b.place_piece(RECEIVER_SCENE, Hex.new(-1, -1, 2))
		chunk_a.remove_piece_at(Hex.new(1, 1, -2))
		var pairs = world.get_connected_chunk_pairs()
		assert_eq(pairs, [])


class TestWorldChunkManagement:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_create_chunkで指定hexにChunkが生成される():
		var chunk = world.create_chunk(Hex.new(0, 0))
		assert_not_null(chunk)

	func test_get_chunkで作成済みChunkを取得できる():
		world.create_chunk(Hex.new(0, 0))
		assert_not_null(world.get_chunk(Hex.new(0, 0)))

	func test_get_chunkで存在しないhexはnullを返す():
		assert_null(world.get_chunk(Hex.new(1, 0)))

	func test_同じhexへのcreate_chunkは同一Chunkを返す():
		var a = world.create_chunk(Hex.new(0, 0))
		var b = world.create_chunk(Hex.new(0, 0))
		assert_eq(a, b)

	func test_create_chunkした直後のChunkはデフォルト非表示():
		var chunk = world.create_chunk(Hex.new(0, 0))
		assert_false(chunk.visible)

	func test_create_chunkしたhexはget_chunk_hexesで取得できる():
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		var hexes = world.get_chunk_hexes()
		assert_eq(hexes.size(), 2)


class TestWorldActiveChunk:
	extends GutTest

	var world

	func before_each():
		world = World.new()
		add_child_autofree(world)

	func test_初期状態ではget_active_chunkはnullを返す():
		assert_null(world.get_active_chunk())

	func test_set_active_chunkでそのChunkが表示される():
		world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))
		assert_true(world.get_chunk(Hex.new(0, 0)).visible)

	func test_set_active_chunkで前のアクティブChunkは非表示になる():
		world.create_chunk(Hex.new(0, 0))
		world.create_chunk(Hex.new(1, 0))
		world.set_active_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(1, 0))
		assert_false(world.get_chunk(Hex.new(0, 0)).visible)

	func test_get_active_chunkはアクティブなChunkを返す():
		var chunk = world.create_chunk(Hex.new(0, 0))
		world.set_active_chunk(Hex.new(0, 0))
		assert_eq(world.get_active_chunk(), chunk)
