extends GutTest

const HubGoalsScript = preload("res://scenes/utils/hub_goals.gd")

var goals: Node


func before_each():
	goals = HubGoalsScript.new()
	add_child_autofree(goals)


func _give(cost: Dictionary) -> void:
	for item_id in cost:
		goals.add_stock(item_id, cost[item_id])


# 前提・レベル・在庫をすべて満たしてから研究する
func _research_with_requirements(id: String) -> bool:
	var def = Research.get_def(id)
	for required in def["requires"]:
		_research_with_requirements(required)
	goals.level = maxi(goals.level, def["level"])
	_give(def["cost"])
	return goals.research(id)


class TestDefinitions:
	extends "res://tests/unit/utils/test_research.gd"

	func test_研究が定義されている():
		assert_gt(Research.all_ids().size(), 0)

	func test_すべての研究が名前と説明と価格を持つ():
		for id in Research.all_ids():
			var def = Research.get_def(id)
			assert_ne(def["name"], "", id)
			assert_ne(def["description"], "", id)
			assert_false(def["cost"].is_empty(), "%s の価格" % id)

	func test_価格に使うアイテムはすべて定義済み():
		for id in Research.all_ids():
			for item_id in Research.get_def(id)["cost"]:
				assert_not_null(ItemDB.get_item(item_id), "%s の価格 %s" % [id, item_id])

	func test_前提の研究はすべて存在する():
		for id in Research.all_ids():
			for required in Research.get_def(id)["requires"]:
				assert_true(required in Research.all_ids(), "%s の前提 %s" % [id, required])

	func test_存在しない研究は空の定義を返す():
		assert_true(Research.get_def("unknown").is_empty())

	func test_すべての研究は到達できるハブのレベルで研究できる():
		for id in Research.all_ids():
			assert_lte(Research.get_def(id)["level"], goals.LEVELS.size() + 1, id)


class TestState:
	extends "res://tests/unit/utils/test_research.gd"

	func test_必要なレベルに届いていない研究はレベル不足():
		assert_eq(goals.research_state("belt_speed_1"), Research.State.LOCKED_LEVEL)

	func test_前提の研究が済んでいない研究は前提不足():
		goals.level = 99
		assert_eq(goals.research_state("belt_speed_2"), Research.State.LOCKED_PREREQUISITE)

	func test_条件を満たしていて在庫が足りない研究は在庫不足():
		goals.level = 99
		assert_eq(goals.research_state("belt_speed_1"), Research.State.UNAFFORDABLE)

	func test_条件と在庫を満たした研究は研究できる():
		goals.level = 99
		_give(Research.get_def("belt_speed_1")["cost"])
		assert_eq(goals.research_state("belt_speed_1"), Research.State.AVAILABLE)

	func test_研究済みの研究は完了():
		_research_with_requirements("belt_speed_1")
		assert_eq(goals.research_state("belt_speed_1"), Research.State.DONE)

	func test_状態ごとに研究できない理由を文章にできる():
		assert_eq(goals.research_state_text("belt_speed_1"), "ハブ Lv3 で研究できる")
		goals.level = 99
		assert_eq(goals.research_state_text("belt_speed_2"), "先に「コンベア高速化 I」が必要")
		assert_eq(goals.research_state_text("belt_speed_1"), "在庫不足")


class TestResearching:
	extends "res://tests/unit/utils/test_research.gd"

	func test_研究すると在庫から価格が引かれ研究済みになる():
		goals.level = 99
		goals.add_stock("iron_ingot", 25)
		assert_true(goals.research("belt_speed_1"))
		assert_true(goals.is_researched("belt_speed_1"))
		assert_eq(goals.get_stock("iron_ingot"), 5)

	func test_条件を満たさない研究はできず在庫も減らない():
		goals.add_stock("iron_ingot", 25)
		assert_false(goals.research("belt_speed_1"))
		assert_false(goals.is_researched("belt_speed_1"))
		assert_eq(goals.get_stock("iron_ingot"), 25)

	func test_同じ研究は二度できない():
		_research_with_requirements("belt_speed_1")
		_give(Research.get_def("belt_speed_1")["cost"])
		assert_false(goals.research("belt_speed_1"))

	func test_存在しない研究はできない():
		assert_false(goals.research("unknown"))

	func test_研究すると通知される():
		watch_signals(goals)
		_research_with_requirements("belt_speed_1")
		assert_signal_emitted(goals, "research_changed")

	func test_リセットすると研究は未完了に戻る():
		_research_with_requirements("belt_speed_1")
		goals.reset()
		assert_false(goals.is_researched("belt_speed_1"))


class TestUnlocks:
	extends "res://tests/unit/utils/test_research.gd"

	func test_機械はハブのレベルが上がると自動で解放される():
		var expected = [
			"unlock_smelter", "unlock_assembler", "unlock_cutter_and_splitter", "unlock_mixer"
		]
		for reward in expected:
			assert_false(goals.is_reward_unlocked(reward), reward)
			goals.advance_level()
			assert_true(goals.is_reward_unlocked(reward), reward)

	func test_機械の解放は研究の一覧に並ばない():
		var machine_rewards = [
			"unlock_smelter", "unlock_assembler", "unlock_cutter_and_splitter", "unlock_mixer"
		]
		for id in Research.all_ids():
			var reward = Research.get_def(id)["effect"].get("unlock", "")
			assert_false(reward in machine_rewards, id)

	func test_チェストはレベルが上がっただけでは解放されない():
		for i in 10:
			goals.advance_level()
		assert_false(goals.is_reward_unlocked("unlock_chunk_chest"))

	func test_チェストは研究すると解放される():
		watch_signals(goals)
		assert_true(_research_with_requirements("unlock_chunk_chest"))
		assert_true(goals.is_reward_unlocked("unlock_chunk_chest"))
		assert_signal_emitted(goals, "unlocks_changed")

	func test_ツールバーのピースはすべて何らかの方法で解放できる():
		var obtainable = {"": true}
		for level in goals.LEVELS:
			obtainable[level["reward"]] = true
		for id in Research.all_ids():
			obtainable[Research.get_def(id)["effect"].get("unlock", "")] = true
		for reward in PieceData.UNLOCK_REWARDS.values():
			assert_true(obtainable.has(reward), "%s を解放する手段がある" % reward)


class TestSpeedBonuses:
	extends "res://tests/unit/utils/test_research.gd"

	func test_研究前のコンベア速度と採掘速度は等倍():
		assert_eq(goals.get_belt_speed(), 1.0)
		assert_eq(goals.get_mining_speed(), 1.0)

	func test_コンベア高速化を研究すると速度の倍率が上がる():
		_research_with_requirements("belt_speed_1")
		assert_eq(goals.get_belt_speed(), 1.5)

	func test_上位のコンベア高速化はさらに速い():
		_research_with_requirements("belt_speed_2")
		assert_eq(goals.get_belt_speed(), 2.0)

	func test_採掘高速化を研究すると採掘の倍率が上がる():
		_research_with_requirements("mining_speed_1")
		assert_eq(goals.get_mining_speed(), 1.5)
		assert_eq(goals.get_belt_speed(), 1.0)
