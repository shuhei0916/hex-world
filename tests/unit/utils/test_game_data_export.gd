extends GutTest

# ゲームのデータ（アイテム・レシピ・研究・目標・設置コスト）を1つの辞書にまとめる。
# tools/research/hex_world.py が、他の自動化ゲームと同じ形の集計をするのに使う。

var data: Dictionary


func before_each():
	data = GameDataExport.to_dict()


func test_登録済みのアイテムをすべて表示名つきで出す():
	var ids = data["items"].map(func(item): return item["id"])
	assert_eq(ids, ItemDB.all_ids())
	assert_eq(data["items"][0], {"id": "iron_ore", "name": "Iron Ore"})


func test_バイオームと採れる資源を出す():
	assert_eq(data["biomes"].size(), Biome.all_ids().size())
	assert_has(data["biomes"], {"id": "plains", "name": "平原", "resource": "iron_ore"})


func test_レシピを機械の名前つきで出す():
	assert_has(
		data["recipes"],
		{
			"machine": "smelter",
			"inputs": {"iron_ore": 1},
			"outputs": {"iron_ingot": 1},
			"time": 2.0,
		}
	)


func test_採掘のレシピも出す():
	assert_has(
		data["recipes"],
		{"machine": "miner", "inputs": {}, "outputs": {"sand": 1}, "time": 1.0},
	)


func test_研究を定義のまま出す():
	assert_eq(data["research"].size(), Research.all_ids().size())
	var first = data["research"][0]
	assert_eq(first["id"], "mining_speed_1")
	assert_eq(first["cost"], {"iron_ore": 20})
	assert_eq(first["requires"], [])
	assert_eq(first["level"], 2)


func test_ハブの目標をレベル順に出す():
	assert_eq(data["levels"].size(), HubGoals.LEVELS.size())
	assert_eq(
		data["levels"][0],
		{"level": 1, "goal_item": "iron_ore", "required": 10, "reward": "unlock_smelter"},
	)


func test_設置コストをピースの名前で出す():
	assert_has(data["build_costs"], {"piece": "smelter_t1", "cost": {"iron_ore": 5}})
