extends GutTest

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER_T1 = preload("res://scenes/components/piece/miner_t1.tscn")
const MINER_T2 = preload("res://scenes/components/piece/miner_t2.tscn")
const SMELTER_T1 = preload("res://scenes/components/piece/smelter_t1.tscn")
const HUB = preload("res://scenes/components/piece/hub.tscn")


func test_コンベアは無料():
	assert_eq(BuildCost.of_scene(CONVEYOR), {})


func test_最初の採掘機は無料():
	assert_eq(BuildCost.of_scene(MINER_T1), {})


func test_ハブは無料():
	assert_eq(BuildCost.of_scene(HUB), {})


func test_Smelterの設置には鉄鉱石が要る():
	assert_eq(BuildCost.of_scene(SMELTER_T1), {"iron_ore": 5})


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
