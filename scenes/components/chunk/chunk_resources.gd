extends RefCounted

# ChunkResources - ヘックスの資源（鉱床）管理と採掘制約の適用を担当する

const RESOURCE_COLORS = {
	"iron_ore": Color("#8B6914"),
}

var _resources: Dictionary = {}


func mark_resource_hex(hex: Hex, resource_type: String) -> void:
	_resources[Hex.to_key(hex)] = resource_type


func get_hex_resource(hex: Hex) -> String:
	return _resources.get(Hex.to_key(hex), "")


func generate_ore_deposits(count: int, inner_hexes: Array[Hex], hex_grid) -> Array[Hex]:
	if inner_hexes.is_empty():
		return []
	var inner_set: Dictionary = {}
	for hex in inner_hexes:
		if not hex_grid.is_occupied(hex):
			inner_set[Hex.to_key(hex)] = hex

	var inner = inner_hexes.filter(func(h): return Hex.to_key(h) in inner_set)
	if inner.is_empty():
		return []
	inner.shuffle()
	var cluster: Array[Hex] = [inner[0]]
	var cluster_set: Dictionary = {Hex.to_key(inner[0]): true}
	var frontier: Array[Hex] = [inner[0]]

	while cluster.size() < count and not frontier.is_empty():
		frontier.shuffle()
		var current = frontier.pop_back()
		for dir in range(6):
			var neighbor = Hex.neighbor(current, dir)
			var key = Hex.to_key(neighbor)
			if key in inner_set and not (key in cluster_set) and not (key in _resources):
				cluster.append(neighbor)
				cluster_set[key] = true
				frontier.append(neighbor)
				if cluster.size() >= count:
					break

	for hex in cluster:
		mark_resource_hex(hex, "iron_ore")
	return cluster


func apply_mining_constraint(piece: Piece, occupied_hexes: Array[Hex]) -> void:
	if piece.piece_type != PieceData.Type.MINER:
		return
	var ore_count = 0
	for hex in occupied_hexes:
		if get_hex_resource(hex) == "iron_ore":
			ore_count += 1
	if ore_count == 0:
		piece.set_recipe(null)
	else:
		piece.set_output_multiplier(ore_count)
