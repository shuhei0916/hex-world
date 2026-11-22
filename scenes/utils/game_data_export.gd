class_name GameDataExport
extends RefCounted

## ゲームのデータ（アイテム・バイオーム・レシピ・研究・目標・設置コスト）を1つの辞書にまとめる。
## tools/scenarios/export_game_data.gd が JSON に書き出し、tools/research/hex_world.py が
## 他の自動化ゲームと同じ形の集計（段階・入力数・研究の深さ）をする。


static func to_dict() -> Dictionary:
	return {
		"items": _items(),
		"biomes": _biomes(),
		"recipes": _recipes(),
		"research": _research(),
		"levels": _levels(),
		"build_costs": _build_costs(),
	}


static func _items() -> Array:
	var out := []
	for id in ItemDB.all_ids():
		out.append({"id": id, "name": ItemDB.get_item(id).display_name})
	return out


static func _biomes() -> Array:
	var out := []
	for id in Biome.all_ids():
		var biome := Biome.get_biome(id)
		out.append({"id": id, "name": biome.display_name, "resource": biome.resource_type})
	return out


static func _recipes() -> Array:
	var out := []
	for piece_type in PieceData.Type.values():
		var machine: String = PieceData.Type.keys()[piece_type].to_lower()
		for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
			var row := {"machine": machine, "inputs": recipe.inputs, "outputs": recipe.outputs}
			row["time"] = recipe.craft_time
			out.append(row)
	return out


static func _research() -> Array:
	var out := []
	for id in Research.all_ids():
		var def := Research.get_def(id).duplicate()
		def["id"] = id
		out.append(def)
	return out


static func _levels() -> Array:
	var out := []
	for i in HubGoals.LEVELS.size():
		var goal: Dictionary = HubGoals.LEVELS[i].duplicate()
		goal["level"] = i + 1
		out.append(goal)
	return out


static func _build_costs() -> Array:
	var out := []
	for path in BuildCost.COSTS:
		out.append({"piece": path.get_file().get_basename(), "cost": BuildCost.COSTS[path]})
	return out
