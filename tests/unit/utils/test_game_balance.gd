extends GutTest

# データ同士の整合（docs/recipe_plan.md の方針）を確かめる。
# アイテム・レシピ・研究・目標を足したとき、払えない値段や使い道のないアイテムが紛れ込まないようにする。
#
# 「レベル L の時点」とは、ハブのレベルが L のときのこと。
# レベル i の目標を納めた報酬は、レベル i + 1 から使える。研究の解放は、その研究のレベルから。

const MACHINES = [
	PieceData.Type.MINER,
	PieceData.Type.SMELTER,
	PieceData.Type.CUTTER,
	PieceData.Type.MIXER,
	PieceData.Type.ASSEMBLER,
]


func test_作れるアイテムはどれも使い道がある():
	for item in ItemDB.all_ids():
		assert_true(_is_used(item), "%s の使い道がない（材料・設置・研究・目標のどれにも使われていない）" % item)


func test_ハブの目標はそのレベルの時点で作れる物():
	for i in HubGoals.LEVELS.size():
		var level = i + 1
		var item: String = HubGoals.LEVELS[i]["goal_item"]
		assert_true(_producible_at(level).has(item), "Lv%d の目標 %s がまだ作れない" % [level, item])


func test_研究の値段は研究できるレベルの時点で作れる物で払える():
	for id in Research.all_ids():
		var def = Research.get_def(id)
		var producible = _producible_at(def["level"])
		for item in def["cost"]:
			assert_true(
				producible.has(item), "研究 %s（Lv%d）の値段 %s がまだ作れない" % [id, def["level"], item]
			)


func test_設置コストはそのピースが解放される時点で作れる物で払える():
	for path in BuildCost.COSTS:
		if _bought_later(path):
			continue
		var piece_type = _piece_type_of(path)
		var level = _unlock_level(PieceData.UNLOCK_REWARDS.get(piece_type, ""))
		var producible = _producible_at(level)
		for item in BuildCost.COSTS[path]:
			assert_true(
				producible.has(item),
				"%s（Lv%d で解放）の設置コスト %s がまだ作れない" % [path.get_file(), level, item]
			)


func test_研究の前提は存在し_前提のほうが先に研究できる():
	for id in Research.all_ids():
		var def = Research.get_def(id)
		for required in def["requires"]:
			var req_def = Research.get_def(required)
			assert_false(req_def.is_empty(), "%s の前提 %s が無い" % [id, required])
			if not req_def.is_empty():
				assert_lte(req_def["level"], def["level"], "%s の前提 %s のほうがあとで開く" % [id, required])


func test_研究の前提はループしていない():
	for id in Research.all_ids():
		assert_false(_reaches(id, id, {}), "%s の前提をたどると自分に戻る" % id)


func test_あとで買う前提のピースも_いつかは作れる物で払える():
	var producible = _producible_at(HubGoals.LEVELS.size())
	for path in BuildCost.COSTS:
		for item in BuildCost.COSTS[path]:
			assert_true(producible.has(item), "%s の設置コスト %s が最後まで作れない" % [path.get_file(), item])


# ---- 補助 ----------------------------------------------------------------------


# 解放と同時ではなく、しばらくあとで買う前提の値段にしてあるピース。
# t2 は t1 と同時に解放されるが高い（test_build_cost.gd と同じ扱い）。
# 橋は最初から置けるが、値段の鉄インゴットは Smelter が開くまで作れない。
func _bought_later(path: String) -> bool:
	return "_t2" in path or path.get_file() == "bridge.tscn"


func _is_used(item: String) -> bool:
	for piece_type in MACHINES:
		for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
			if recipe.inputs.has(item):
				return true
	for cost in BuildCost.COSTS.values():
		if cost.has(item):
			return true
	for id in Research.all_ids():
		if Research.get_def(id)["cost"].has(item):
			return true
	return HubGoals.LEVELS.any(func(goal): return goal["goal_item"] == item)


# 報酬が使えるようになるレベル。"" は最初から。どこにも無ければ大きな値（解放されない）
func _unlock_level(reward: String) -> int:
	if reward == "":
		return 1
	for i in HubGoals.LEVELS.size():
		if HubGoals.LEVELS[i]["reward"] == reward:
			return i + 2
	for id in Research.all_ids():
		var def = Research.get_def(id)
		if def["effect"].get(Research.UNLOCK, "") == reward:
			return def["level"]
	return 1 << 20


# レベル L の時点で、解放済みの機械だけで作れるアイテム（原料はどのバイオームも採れる前提）
func _producible_at(level: int) -> Dictionary:
	var producible := {}
	var changed := true
	while changed:
		changed = false
		for piece_type in MACHINES:
			if _unlock_level(PieceData.UNLOCK_REWARDS.get(piece_type, "")) > level:
				continue
			for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
				if not recipe.inputs.keys().all(func(item): return producible.has(item)):
					continue
				for item in recipe.outputs:
					if not producible.has(item):
						producible[item] = true
						changed = true
	return producible


func _piece_type_of(path: String) -> PieceData.Type:
	var piece = load(path).instantiate()
	var piece_type = piece.piece_type
	piece.free()
	return piece_type


func _reaches(from: String, target: String, seen: Dictionary) -> bool:
	for required in Research.get_def(from).get("requires", []):
		if required == target:
			return true
		if not seen.has(required):
			seen[required] = true
			if _reaches(required, target, seen):
				return true
	return false
