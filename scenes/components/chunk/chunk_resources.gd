class_name ChunkResources
extends RefCounted

# ChunkResources - ヘックスの資源（鉱床）管理と採掘制約の適用を担当する

const RESOURCE_COLORS = {
	"iron_ore": Color("#8B6914"),
	"copper_ore": Color("#b8562a"),
	"coal": Color("#1e1e1e"),
	"sand": Color("#c9ad6a"),
	"limestone": Color("#b9b4a0"),
}

var _resources: Dictionary = {}


func mark_resource_hex(hex: Vector2i, resource_type: String) -> void:
	_resources[hex] = resource_type


func get_hex_resource(hex: Vector2i) -> String:
	return _resources.get(hex, "")


# candidates（空いているマス）の中に、count マスがつながった鉱床を作る
func generate_ore_deposits(
	count: int, candidates: Array, resource_type: String = "iron_ore"
) -> Array[Vector2i]:
	# すでに鉱床のあるマスは、起点にも広げる先にもしない
	var free: Dictionary = {}
	for hex in candidates:
		if not _resources.has(hex):
			free[hex] = true
	if free.is_empty():
		return []
	var seed_hex: Vector2i = free.keys().pick_random()
	var cluster: Array[Vector2i] = [seed_hex]
	free.erase(seed_hex)
	var frontier: Array[Vector2i] = [seed_hex]

	while cluster.size() < count and not frontier.is_empty():
		frontier.shuffle()
		var current = frontier.pop_back()
		for neighbor in Hex.neighbors(current):
			if not free.has(neighbor):
				continue
			cluster.append(neighbor)
			free.erase(neighbor)
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
	piece.set_speed_multiplier(counts[best])
