class_name Planet
extends RefCounted

# Planet - 惑星を構成する chunk の配置（六角形）と、各 chunk のバイオームを表すデータモデル。
# chunk の実体（Chunk ノード）は持たず、座標とその属性だけを扱う。
#
# バイオームは「地域(region)」単位で割り当てる。地域は種 chunk から1マスずつ順番に
# 広げて作るため、必ず連結し、大きさもおおむね揃う。原点の地域は常に平原。

const DEFAULT_REGION_COUNT := 8
# 種 chunk 同士をこの距離以上離す（隣接した種に囲まれて地域が1マスで止まるのを防ぐ）
const MIN_SEED_DISTANCE := 2
# 隣接地域を異なるバイオームで塗り分けられる地域分けが得られるまで作り直す回数の上限
const MAX_REGION_ATTEMPTS := 20

var radius: int
var seed_value: int

var _chunk_hexes: Array[Hex] = []
var _chunk_keys: Dictionary = {}
var _region_ids: Dictionary = {}  # Hex.to_key → 地域番号
var _region_biomes: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _init(radius_val: int, seed_val: int, region_count: int = DEFAULT_REGION_COUNT) -> void:
	radius = radius_val
	seed_value = seed_val
	_rng.seed = seed_val
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			var hex = Hex.new(q, r)
			_chunk_hexes.append(hex)
			_chunk_keys[Hex.to_key(hex)] = true
	_generate_regions(mini(region_count, _chunk_hexes.size()))


func get_chunk_hexes() -> Array[Hex]:
	return _chunk_hexes.duplicate()


func has_chunk(hex: Hex) -> bool:
	return Hex.to_key(hex) in _chunk_keys


func get_region_count() -> int:
	return _region_biomes.size()


func get_region_id(hex: Hex) -> int:
	return _region_ids.get(Hex.to_key(hex), -1)


func get_biome_id(hex: Hex) -> String:
	var region = get_region_id(hex)
	if region == -1:
		return ""
	return _region_biomes[region]


func get_biome(hex: Hex) -> Biome:
	return Biome.get_biome(get_biome_id(hex))


func _generate_regions(region_count: int) -> void:
	for _attempt in range(MAX_REGION_ATTEMPTS):
		_grow_regions(region_count)
		if _assign_biomes(region_count):
			return
	# 塗り分けられない場合は隣接の重複を許して割り当てる（最後の地域分けをそのまま使う）
	_region_biomes.clear()
	for region in range(region_count):
		_region_biomes.append(Biome.PLAINS if region == 0 else _random_biome())


func _grow_regions(region_count: int) -> void:
	_region_ids.clear()
	var frontiers: Array = []
	for seed_hex in _pick_seed_hexes(region_count):
		_region_ids[Hex.to_key(seed_hex)] = frontiers.size()
		frontiers.append([seed_hex])

	var grew := true
	while grew:
		grew = false
		for region in range(frontiers.size()):
			if _grow_region(region, frontiers[region]):
				grew = true


# 原点の地域(0番)を平原に固定し、隣接する地域が異なるバイオームになるよう
# バックトラックで塗り分ける。候補は使用回数が少ない順（同数なら乱数順）に試すので、
# バイオームの出現数が偏りにくい。塗り分けられなければ false。
func _assign_biomes(region_count: int) -> bool:
	var adjacency = _region_adjacency(region_count)
	var assigned: Array[String] = []
	assigned.resize(region_count)
	assigned[0] = Biome.PLAINS
	var usage = {}
	for id in Biome.all_ids():
		usage[id] = 0
	usage[Biome.PLAINS] = 1
	if not _color_regions(1, adjacency, assigned, usage):
		return false
	_region_biomes = assigned
	return true


func _color_regions(
	region: int, adjacency: Array, assigned: Array[String], usage: Dictionary
) -> bool:
	if region == assigned.size():
		return true
	var candidates = Biome.all_ids().filter(
		func(id): return adjacency[region].keys().all(func(n): return assigned[n] != id)
	)
	_shuffle(candidates)
	candidates.sort_custom(func(a, b): return usage[a] < usage[b])
	for id in candidates:
		assigned[region] = id
		usage[id] += 1
		if _color_regions(region + 1, adjacency, assigned, usage):
			return true
		usage[id] -= 1
		assigned[region] = ""
	return false


func _random_biome() -> String:
	var ids = Biome.all_ids()
	return ids[_rng.randi_range(0, ids.size() - 1)]


func _region_adjacency(region_count: int) -> Array:
	var adjacency = []
	for i in range(region_count):
		adjacency.append({})
	for hex in _chunk_hexes:
		var region = get_region_id(hex)
		for dir in range(6):
			var other = get_region_id(Hex.neighbor(hex, dir))
			if other != -1 and other != region:
				adjacency[region][other] = true
	return adjacency


# 地域を隣接する未割り当て chunk へ1マスだけ広げる。広げられなければ false。
func _grow_region(region: int, frontier: Array) -> bool:
	var candidates = _unassigned_neighbors(frontier)
	if candidates.is_empty():
		return false
	var hex: Hex = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_region_ids[Hex.to_key(hex)] = region
	frontier.append(hex)
	return true


func _unassigned_neighbors(frontier: Array) -> Array[Hex]:
	var result: Array[Hex] = []
	var seen = {}
	for i in range(frontier.size() - 1, -1, -1):
		var has_open_side := false
		for dir in range(6):
			var neighbor = Hex.neighbor(frontier[i], dir)
			var key = Hex.to_key(neighbor)
			if not has_chunk(neighbor) or key in _region_ids:
				continue
			has_open_side = true
			if not key in seen:
				seen[key] = true
				result.append(neighbor)
		if not has_open_side:
			frontier.remove_at(i)  # 周囲が埋まった chunk は以後調べない
	return result


func _pick_seed_hexes(region_count: int) -> Array[Hex]:
	var seeds: Array[Hex] = [Hex.new(0, 0)]
	var candidates = _chunk_hexes.duplicate()
	_shuffle(candidates)
	for hex in candidates:
		if seeds.size() >= region_count:
			break
		if seeds.all(func(s): return Hex.distance(s, hex) >= MIN_SEED_DISTANCE):
			seeds.append(hex)
	# 距離条件で足りない場合（小さな planet）は条件なしで補う
	for hex in candidates:
		if seeds.size() >= region_count:
			break
		if not seeds.any(func(s): return Hex.equals(s, hex)):
			seeds.append(hex)
	return seeds


# Array.shuffle() はグローバル乱数を使うため、シード付きの _rng で Fisher-Yates を行う
func _shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j = _rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
