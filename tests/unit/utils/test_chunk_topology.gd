extends GutTest

## 隣の chunk をローカル画面のどこに描くか（chunk 内の座標で見たずらし量）。
## 隣どうしの chunk はすき間も重なりもなく敷き詰められ、境界の Sender とその先の Receiver は
## 画面上で隣り合うマスになる。

const RADIUS := 5


func _all_hexes(radius: int) -> Array[Hex]:
	var result: Array[Hex] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			result.append(Hex.new(q, r))
	return result


func _edge_direction(hex: Hex, radius: int) -> int:
	var on_edge := [
		hex.q == radius,
		hex.r == -radius,
		hex.s == radius,
		hex.q == -radius,
		hex.r == radius,
		hex.s == -radius,
	]
	if on_edge.count(true) != 1:
		return -1
	return on_edge.find(true)


func test_自分自身のずらし量は0():
	assert_true(Hex.equals(ChunkTopology.chunk_offset(Hex.new(0, 0), RADIUS), Hex.new(0, 0)))


func test_Senderの対応位置のReceiverは画面上で隣のマスになる():
	for hex in _all_hexes(RADIUS):
		var edge_dir = _edge_direction(hex, RADIUS)
		if edge_dir == -1:
			continue
		var neighbor_chunk = Hex.direction(ChunkTopology.to_world_direction(edge_dir))
		var offset = ChunkTopology.chunk_offset(neighbor_chunk, RADIUS)
		var receiver = Hex.add(ChunkTopology.mirror_hex(hex, edge_dir), offset)
		assert_eq(Hex.distance(hex, receiver), 1, "%s (辺 %d)" % [hex, edge_dir])


func test_周りの6つのchunkと重ならずすき間なく敷き詰められる():
	var owners := {}
	var deltas: Array[Hex] = [Hex.new(0, 0)]
	for dir in range(6):
		deltas.append(Hex.direction(dir))
	for delta in deltas:
		var offset = ChunkTopology.chunk_offset(delta, RADIUS)
		for hex in _all_hexes(RADIUS):
			var key = Hex.to_key(Hex.add(hex, offset))
			assert_false(owners.has(key), "重なり: %s" % key)
			owners[key] = true
	# 中央の chunk の周りのマスは、すべてどこかの chunk に含まれる
	for hex in _all_hexes(RADIUS + 1):
		assert_true(owners.has(Hex.to_key(hex)), "すき間: %s" % hex)


func test_ずらし量はchunkの大きさに応じて変わる():
	var small = ChunkTopology.chunk_offset(Hex.direction(0), 2)
	var large = ChunkTopology.chunk_offset(Hex.direction(0), 5)
	assert_lt(Hex.distance(Hex.new(0, 0), small), Hex.distance(Hex.new(0, 0), large))
