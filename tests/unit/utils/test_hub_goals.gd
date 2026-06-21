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
