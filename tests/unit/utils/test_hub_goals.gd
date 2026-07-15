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
