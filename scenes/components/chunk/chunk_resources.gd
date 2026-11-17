extends RefCounted

# ChunkResources - ヘックスの資源（鉱床）管理と採掘制約の適用を担当する

const RESOURCE_COLORS = {
	"iron_ore": Color("#8B6914"),
	"copper_ore": Color("#b8562a"),
	"coal": Color("#1e1e1e"),
	"sand": Color("#c9ad6a"),
}

var _resources: Dictionary = {}


func mark_resource_hex(hex: Vector2i, resource_type: String) -> void:
	_resources[hex] = resource_type


func get_hex_resource(hex: Vector2i) -> String:
	return _resources.get(hex, "")


func generate_ore_deposits(
	count: int, inner_hexes: Array[Vector2i], hex_grid, resource_type: String = "iron_ore"
) -> Array[Vector2i]:
	if inner_hexes.is_empty():
		return []
	var inner_set: Dictionary = {}
	for hex in inner_hexes:
		if not hex_grid.is_occupied(hex):
			inner_set[hex] = hex

	var inner = inner_hexes.filter(func(h): return h in inner_set)
	if inner.is_empty():
		return []
	inner.shuffle()
	var cluster: Array[Vector2i] = [inner[0]]
	var cluster_set: Dictionary = {inner[0]: true}
	var frontier: Array[Vector2i] = [inner[0]]

	while cluster.size() < count and not frontier.is_empty():
		frontier.shuffle()
		var current = frontier.pop_back()
		for dir in range(6):
			var neighbor = Hex.neighbor(current, dir)
			var key = neighbor
			if key in inner_set and not (key in cluster_set) and not (key in _resources):
				cluster.append(neighbor)
				cluster_set[key] = true
				frontier.append(neighbor)
				if cluster.size() >= count:
					break

	for hex in cluster:
		mark_resource_hex(hex, resource_type)
	return cluster


# Miner は足元で最も多い資源を、その鉱床マス数ぶんの倍率で採掘する。鉱床が無ければ停止。
func apply_mining_constraint(piece: Piece, occupied_hexes: Array[Vector2i]) -> void:
	if piece.piece_type != PieceData.Type.MINER:
		return
	var counts: Dictionary = {}
	for hex in occupied_hexes:
		var resource_type = get_hex_resource(hex)
		if resource_type != "":
			counts[resource_type] = counts.get(resource_type, 0) + 1
	if counts.is_empty():
		piece.set_recipe(null)
		return
	var best: String = counts.keys().reduce(func(a, b): return a if counts[a] >= counts[b] else b)
	piece.set_recipe(Recipe.RecipeDB.get_mining_recipe(best))
	piece.set_output_multiplier(counts[best])
