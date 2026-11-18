extends GutTest

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER_T1 = preload("res://scenes/components/piece/miner_t1.tscn")
const MINER_T2 = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_T1 = preload("res://scenes/components/piece/smelter_t1.tscn")
const HUB = preload("res://scenes/components/piece/hub.tscn")

const MACHINE_TYPES = [
	PieceData.Type.MINER,
	PieceData.Type.SMELTER,
	PieceData.Type.CUTTER,
	PieceData.Type.ASSEMBLER,
	PieceData.Type.MIXER,
	PieceData.Type.KILN,
]


func test_コンベアは無料():
	assert_eq(BuildCost.of_scene(CONVEYOR), {})


func test_最初の採掘機は無料():
	assert_eq(BuildCost.of_scene(MINER_T1), {})


func test_ハブは無料():
	assert_eq(BuildCost.of_scene(HUB), {})


func test_Smelterの設置には鉄鉱石が要る():
	assert_eq(BuildCost.of_scene(SMELTER_T1), {"iron_ore": 5})


func test_窯の設置には鋼が要る():
	assert_eq(BuildCost.of_scene(load(BuildCost.PIECE_DIR + "kiln_t1.tscn")), {"steel": 10})


func test_Biomeチェストの設置にはコンクリートが要る():
	for path in ["biome_chest_in.tscn", "biome_chest_out.tscn"]:
		assert_eq(BuildCost.COSTS[BuildCost.PIECE_DIR + path], {"concrete": 10}, path)


func test_上位の採掘機は有料():
	assert_false(BuildCost.of_scene(MINER_T2).is_empty())


func test_設置済みピースからもコストが分かる():
	var piece = SMELTER_T1.instantiate()
	add_child_autofree(piece)
	assert_eq(BuildCost.of_piece(piece), {"iron_ore": 5})


func test_コンベアと最初の採掘機とハブ以外のツールバーのピースはすべて有料():
	var free_scenes = [CONVEYOR.resource_path, MINER_T1.resource_path]
	for path in BuildCost.COSTS:
		assert_false(path in free_scenes, "%s は無料のはず" % path)
		assert_true(ResourceLoader.exists(path), "%s が存在する" % path)
		assert_false(BuildCost.COSTS[path].is_empty(), "%s のコストが空" % path)


func test_コストに使うアイテムはすべて定義済み():
	for path in BuildCost.COSTS:
		for item in BuildCost.COSTS[path]:
			assert_not_null(ItemDB.get_item(item), "%s のコスト %s" % [path, item])


func test_コストを表示用の文章にできる():
	assert_eq(BuildCost.to_text({"iron_ore": 5}), "Iron Ore 5")
	assert_eq(BuildCost.to_text({}), "なし")


func test_チェストはコンベアより高い():
	for path in ["chest_in.tscn", "chest_out.tscn"]:
		var cost = BuildCost.COSTS.get(BuildCost.PIECE_DIR + path, {})
		assert_false(cost.is_empty(), path)


func test_足りない素材だけを手持ちと必要数で文章にできる():
	HubGoals.reset()
	HubGoals.add_stock("iron_ore", 2)
	HubGoals.add_stock("coal", 9)
	assert_eq(BuildCost.shortage_text({"iron_ore": 5, "coal": 3}), "在庫不足: Iron Ore 2/5")
	HubGoals.reset()


func test_t1の機械の設置コストは_その機械が解放された時点で作れる物で払える():
	# t2 は t1 と同時に解放されるが、しばらく後に買う前提の値段にしてある
	for scene_path in BuildCost.COSTS:
		if "_t2" in scene_path:
			continue
		var piece = load(scene_path).instantiate()
		var piece_type = piece.piece_type
		piece.free()
		if not piece_type in MACHINE_TYPES:
			continue
		var machines = _machines_unlocked_with(piece_type)
		for item in BuildCost.COSTS[scene_path]:
			var needed = _machines_needed(item)
			var missing = needed.filter(func(t): return not machines.has(t))
			assert_eq(missing, [], "%s のコスト %s" % [scene_path.get_file(), item])


# その機械を解放したレベルまでに解放されている機械（採掘機は最初から）
func _machines_unlocked_with(piece_type: int) -> Dictionary:
	var unlocked = {PieceData.Type.MINER: true}
	var reward = PieceData.UNLOCK_REWARDS.get(piece_type, "")
	if reward == "":
		return unlocked
	for level in HubGoals.LEVELS:
		for t in PieceData.UNLOCK_REWARDS:
			if level["reward"] != "" and PieceData.UNLOCK_REWARDS[t] == level["reward"]:
				unlocked[t] = true
		if level["reward"] == reward:
			# 解放されたばかりの機械自身はまだ置けないので、コストには使えない
			unlocked.erase(piece_type)
			return unlocked
	return unlocked


func _machines_needed(item: String) -> Array:
	for piece_type in PieceData.Type.values():
		for recipe in Recipe.RecipeDB.get_recipes_by_type(piece_type):
			if recipe.outputs.has(item):
				var result = [piece_type]
				for input in recipe.inputs:
					for t in _machines_needed(input):
						if not t in result:
							result.append(t)
				return result
	return []
