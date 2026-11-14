# gdlint:disable=constant-name
extends GutTest

const HUB_GOALS_SCRIPT = preload("res://scenes/utils/hub_goals.gd")


class TestHubGoalsLevelDefinition:
	extends GutTest

	var hub_goals: Node

	func before_each():
		hub_goals = HUB_GOALS_SCRIPT.new()
		add_child_autofree(hub_goals)

	func test_レベル1の目標アイテムはiron_ore():
		assert_eq(hub_goals.get_current_goal()["goal_item"], "iron_ore")

	func test_レベル1の必要数は10():
		assert_eq(hub_goals.get_current_goal()["required"], 10)

	func test_レベル1の報酬はunlock_smelter():
		assert_eq(hub_goals.get_current_goal()["reward"], "unlock_smelter")


class TestHubGoalsRewards:
	extends GutTest

	var hub_goals: Node

	func before_each():
		hub_goals = HUB_GOALS_SCRIPT.new()
		add_child_autofree(hub_goals)

	func test_未取得の報酬はfalseを返す():
		assert_false(hub_goals.is_reward_unlocked("unlock_smelter"))

	func test_advance_level後に報酬がtrueになる():
		hub_goals.advance_level()
		assert_true(hub_goals.is_reward_unlocked("unlock_smelter"))

	func test_advance_level後にlevelが増える():
		hub_goals.advance_level()
		assert_eq(hub_goals.level, 2)

	func test_advance_levelでlevel_upシグナルが発火する():
		watch_signals(hub_goals)
		hub_goals.advance_level()
		assert_signal_emitted(hub_goals, "level_up")

	func test_最終レベル超えてadvance_levelしてもクラッシュしない():
		for i in range(10):
			hub_goals.advance_level()
		assert_eq(hub_goals.level, 11)


class TestHubGoalsCreativeMode:
	extends GutTest

	var hub_goals: Node

	func before_each():
		hub_goals = HUB_GOALS_SCRIPT.new()
		add_child_autofree(hub_goals)

	func test_クリエイティブモード中は未取得の報酬もtrueを返す():
		hub_goals.creative_mode = true
		assert_true(hub_goals.is_reward_unlocked("unlock_smelter"))

	func test_クリエイティブモード解除後は通常の判定に戻る():
		hub_goals.creative_mode = true
		hub_goals.creative_mode = false
		assert_false(hub_goals.is_reward_unlocked("unlock_smelter"))

	func test_toggle_creative_modeでフラグが反転する():
		hub_goals.toggle_creative_mode()
		assert_true(hub_goals.creative_mode)

	func test_toggle_creative_modeでunlocks_changedシグナルが発火する():
		watch_signals(hub_goals)
		hub_goals.toggle_creative_mode()
		assert_signal_emitted(hub_goals, "unlocks_changed")


class TestHubGoalsBiomeLevels:
	extends GutTest

	var hub_goals: Node

	func before_each():
		hub_goals = HUB_GOALS_SCRIPT.new()
		add_child_autofree(hub_goals)

	func _advance_to(goal_item: String) -> void:
		for i in range(20):
			if hub_goals.get_current_goal()["goal_item"] == goal_item:
				return
			hub_goals.advance_level()

	func test_ネジの次は銅インゴットが目標になる():
		_advance_to("screw")
		hub_goals.advance_level()
		assert_eq(hub_goals.get_current_goal()["goal_item"], "copper_ingot")

	func test_銅インゴットの次は鋼材が目標になる():
		_advance_to("copper_ingot")
		hub_goals.advance_level()
		assert_eq(hub_goals.get_current_goal()["goal_item"], "steel")

	func test_鋼材のあとは銅線_鉄骨_回路の順に目標になる():
		_advance_to("steel")
		for expected in ["copper_wire", "steel_beam", "circuit"]:
			hub_goals.advance_level()
			assert_eq(hub_goals.get_current_goal()["goal_item"], expected)

	func test_すべての目標アイテムは定義済みで_作るレシピか採掘で手に入る():
		for level in hub_goals.LEVELS:
			var item = level["goal_item"]
			assert_not_null(ItemDB.get_item(item), item)
			assert_not_null(Recipe.RecipeDB.get_recipe(item), "%s のレシピ" % item)


class TestHubGoalsStock:
	extends GutTest

	var hub_goals: Node

	func before_each():
		hub_goals = HUB_GOALS_SCRIPT.new()
		add_child_autofree(hub_goals)

	func test_最初は在庫が無い():
		assert_eq(hub_goals.get_stock("iron_ore"), 0)

	func test_在庫に加えた分だけ増える():
		hub_goals.add_stock("iron_ore", 3)
		hub_goals.add_stock("iron_ore", 2)
		assert_eq(hub_goals.get_stock("iron_ore"), 5)

	func test_在庫が足りていれば支払える():
		hub_goals.add_stock("iron_ore", 5)
		assert_true(hub_goals.can_afford({"iron_ore": 5}))

	func test_在庫が1種類でも足りなければ支払えない():
		hub_goals.add_stock("iron_ore", 5)
		assert_false(hub_goals.can_afford({"iron_ore": 5, "coal": 1}))

	func test_コストが空なら在庫が無くても支払える():
		assert_true(hub_goals.can_afford({}))

	func test_支払うと在庫が減る():
		hub_goals.add_stock("iron_ore", 5)
		assert_true(hub_goals.pay({"iron_ore": 3}))
		assert_eq(hub_goals.get_stock("iron_ore"), 2)

	func test_足りないときは支払われず在庫も減らない():
		hub_goals.add_stock("iron_ore", 2)
		hub_goals.add_stock("coal", 9)
		assert_false(hub_goals.pay({"iron_ore": 3, "coal": 1}))
		assert_eq(hub_goals.get_stock("coal"), 9)

	func test_払い戻すと在庫が戻る():
		hub_goals.refund({"iron_ore": 3})
		assert_eq(hub_goals.get_stock("iron_ore"), 3)

	func test_クリエイティブモードでは在庫が無くても支払え在庫は減らない():
		hub_goals.add_stock("iron_ore", 1)
		hub_goals.creative_mode = true
		assert_true(hub_goals.pay({"iron_ore": 5}))
		assert_eq(hub_goals.get_stock("iron_ore"), 1)

	func test_クリエイティブモードでは払い戻しで在庫が増えない():
		hub_goals.creative_mode = true
		hub_goals.refund({"iron_ore": 5})
		assert_eq(hub_goals.get_stock("iron_ore"), 0)

	func test_在庫が変わると通知される():
		watch_signals(hub_goals)
		hub_goals.add_stock("iron_ore", 1)
		assert_signal_emitted(hub_goals, "stock_changed")

	func test_リセットすると在庫が空になる():
		hub_goals.add_stock("iron_ore", 5)
		hub_goals.reset()
		assert_eq(hub_goals.get_stock("iron_ore"), 0)
