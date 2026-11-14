extends GutTest

## 隣の chunk をローカル画面のどこに描くか（chunk 内の座標で見たずらし量）。
## 隣の chunk は、境界の辺に垂直な向きへまっすぐずらして置く。ずらす向きはマスの並びの斜め方向
## （hex_diagonals）なので、ずらしてもマスの格子からはずれない。
## その結果、6つの隣はワールドマップと同じ正六角形に並び、chunk の間には溝ができ、
## 辺の対応位置（mirror_hex）どうしは溝をはさんで真正面に向かい合う。

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


func _pixel(hex: Hex) -> Vector2:
	return Layout.hex_to_pixel(Layout.make_default(), hex)


func test_自分自身のずらし量は0():
	assert_true(Hex.equals(ChunkTopology.chunk_offset(Hex.new(0, 0), RADIUS, 2), Hex.new(0, 0)))


func test_辺の対応位置どうしは溝をはさんで辺に垂直に真正面に向かい合う():
	for gap_steps in [1, 2, 3]:
		for hex in _all_hexes(RADIUS):
			var edge_dir = _edge_direction(hex, RADIUS)
			if edge_dir == -1:
				continue
			var neighbor_chunk = Hex.direction(ChunkTopology.to_world_direction(edge_dir))
			var offset = ChunkTopology.chunk_offset(neighbor_chunk, RADIUS, gap_steps)
			var across = Hex.add(ChunkTopology.mirror_hex(hex, edge_dir), offset)
			var expected = Hex.add(hex, Hex.scale(Hex.hex_diagonals[edge_dir], gap_steps))
			assert_true(
				Hex.equals(across, expected), "%s (辺 %d, 溝 %d)" % [hex, edge_dir, gap_steps]
			)


func test_隣のchunkはワールドマップと同じ向きに並ぶ():
	var map_layout = Layout.new(Layout.layout_flat, Vector2(1, 1), Vector2.ZERO)
	for dir in range(6):
		var delta = Hex.direction(dir)
		var local = _pixel(ChunkTopology.chunk_offset(delta, RADIUS, 2)).normalized()
		var on_map = Layout.hex_to_pixel(map_layout, delta).normalized()
		assert_almost_eq(local.dot(on_map), 1.0, 0.0001, "方向 %d" % dir)


func test_周りの6つのchunkと重ならない():
	for gap_steps in [1, 2, 3]:
		var owners := {}
		var deltas: Array[Hex] = [Hex.new(0, 0)]
		for dir in range(6):
			deltas.append(Hex.direction(dir))
		for delta in deltas:
			var offset = ChunkTopology.chunk_offset(delta, RADIUS, gap_steps)
			for hex in _all_hexes(RADIUS):
				var key = Hex.to_key(Hex.add(hex, offset))
				assert_false(owners.has(key), "重なり: %s (溝 %d)" % [key, gap_steps])
				owners[key] = true


func test_溝を広げるほど隣のchunkは遠くなる():
	var near = ChunkTopology.chunk_offset(Hex.direction(0), RADIUS, 1)
	var far = ChunkTopology.chunk_offset(Hex.direction(0), RADIUS, 3)
	assert_lt(_pixel(near).length(), _pixel(far).length())


func test_離れたchunkのずらし量は隣のずらし量を足したもの():
	var east = ChunkTopology.chunk_offset(Hex.direction(0), RADIUS, 2)
	var two_east = ChunkTopology.chunk_offset(Hex.new(2, 0), RADIUS, 2)
	assert_true(Hex.equals(two_east, Hex.scale(east, 2)))
