extends GutTest


class TestChunkLayout:
	extends GutTest

	func test_半径Rのplanetは六角形に並ぶ3R_R加1_加1個のchunkを持つ():
		var planet = Planet.new(4, 1)
		assert_eq(planet.get_chunk_hexes().size(), 61)

	func test_半径内のhexはplanetのchunkである():
		var planet = Planet.new(2, 1)
		assert_true(planet.has_chunk(Hex.new(2, -1)))

	func test_半径外のhexはplanetのchunkではない():
		var planet = Planet.new(2, 1)
		assert_false(planet.has_chunk(Hex.new(3, 0)))


class TestBiomeAssignment:
	extends GutTest

	func test_全chunkにバイオームが割り当てられる():
		var planet = Planet.new(4, 1)
		for hex in planet.get_chunk_hexes():
			assert_not_null(Biome.get_biome(planet.get_biome_id(hex)), str(hex))

	func test_planet外のhexのバイオームは空文字():
		var planet = Planet.new(2, 1)
		assert_eq(planet.get_biome_id(Hex.new(3, 0)), "")

	func test_原点chunkは必ず平原になる():
		for seed_val in range(10):
			var planet = Planet.new(4, seed_val)
			assert_eq(planet.get_biome_id(Hex.new(0, 0)), Biome.PLAINS, "seed=%d" % seed_val)

	func test_同じシードなら同じバイオーム配置になる():
		assert_eq(_biome_map(Planet.new(4, 42)), _biome_map(Planet.new(4, 42)))

	func test_シードが違えばバイオーム配置が変わる():
		assert_ne(_biome_map(Planet.new(4, 1)), _biome_map(Planet.new(4, 2)))

	func test_全種類のバイオームが出現する():
		var planet = Planet.new(4, 1)
		var found = {}
		for hex in planet.get_chunk_hexes():
			found[planet.get_biome_id(hex)] = true
		assert_eq(found.size(), Biome.all_ids().size())

	func test_指定した数の地域に分かれる():
		var planet = Planet.new(4, 1, 6)
		assert_eq(planet.get_region_count(), 6)

	func test_各地域は連結しており複数のchunkからなる():
		for seed_val in range(20):
			var planet = Planet.new(4, seed_val, 6)
			for region in range(planet.get_region_count()):
				var hexes = _region_hexes(planet, region)
				assert_gt(hexes.size(), 1, "seed=%d region=%d" % [seed_val, region])
				assert_true(_is_connected(hexes), "seed=%d region=%d" % [seed_val, region])

	func test_同じ地域のchunkは同じバイオームを持つ():
		var planet = Planet.new(4, 1, 6)
		for region in range(planet.get_region_count()):
			var ids = {}
			for hex in _region_hexes(planet, region):
				ids[planet.get_biome_id(hex)] = true
			assert_eq(ids.size(), 1)

	func _biome_map(planet: Planet) -> Dictionary:
		var result = {}
		for hex in planet.get_chunk_hexes():
			result[Hex.to_key(hex)] = planet.get_biome_id(hex)
		return result

	func _region_hexes(planet: Planet, region: int) -> Array[Hex]:
		var result: Array[Hex] = []
		for hex in planet.get_chunk_hexes():
			if planet.get_region_id(hex) == region:
				result.append(hex)
		return result

	func _is_connected(hexes: Array[Hex]) -> bool:
		if hexes.is_empty():
			return false
		var remaining = {}
		for hex in hexes:
			remaining[Hex.to_key(hex)] = hex
		var stack: Array[Hex] = [hexes[0]]
		remaining.erase(Hex.to_key(hexes[0]))
		while not stack.is_empty():
			var current = stack.pop_back()
			for dir in range(6):
				var key = Hex.to_key(Hex.neighbor(current, dir))
				if key in remaining:
					stack.append(remaining[key])
					remaining.erase(key)
		return remaining.is_empty()
