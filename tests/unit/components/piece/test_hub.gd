# gdlint:disable=constant-name
extends GutTest

const HUB_SCRIPT = preload("res://scenes/components/piece/hub.gd")


class TestHubSetup:
	extends GutTest

	var hub: Node

	func before_each():
		hub = HUB_SCRIPT.new()
		add_child_autofree(hub)

	func test_setup後にgoal_itemが設定される():
		hub.setup("iron_plate", 10)
		assert_eq(hub.goal_item, "iron_plate")

	func test_setup後にgoal_countが設定される():
		hub.setup("iron_plate", 10)
		assert_eq(hub.goal_count, 10)

	func test_received_countの初期値は0():
		assert_eq(hub.received_count, 0)

	func test_add_received後にreceived_countが増える():
		hub.setup("iron_plate", 100)
		hub.add_received(1)
		assert_eq(hub.received_count, 1)

	func test_未達成ではis_completedはfalse():
		hub.setup("iron_plate", 10)
		hub.add_received(5)
		assert_false(hub.is_completed())


class TestHubVisuals:
	extends GutTest

	var hub: Node
	var goal_icon: TextureRect

	func before_each():
		var parent = Node2D.new()
		add_child_autofree(parent)
		goal_icon = TextureRect.new()
		goal_icon.name = "GoalIcon"
		parent.add_child(goal_icon)
		hub = HUB_SCRIPT.new()
		parent.add_child(hub)

	func test_setup後にGoalIconのテクスチャが目標アイテムのアイコンに設定される():
		hub.setup("iron_ore", 10)
		var expected = ItemDB.get_item("iron_ore").icon
		assert_eq(goal_icon.texture, expected)

	func test_ItemDBに存在しないアイテムのときGoalIconはnullのまま():
		hub.setup("unknown_item", 5)
		assert_null(goal_icon.texture)

	func test_setup後にCountLabelが0_goal形式で表示される():
		var count_label := Label.new()
		count_label.name = "CountLabel"
		hub.get_parent().add_child(count_label)
		hub.setup("iron_ore", 10)
		assert_eq(count_label.text, "0/10")


class TestHubCountUpdate:
	extends GutTest

	var hub: Node
	var count_label: Label

	func before_each():
		var parent = Node2D.new()
		add_child_autofree(parent)
		count_label = Label.new()
		count_label.name = "CountLabel"
		parent.add_child(count_label)
		hub = HUB_SCRIPT.new()
		parent.add_child(hub)
		hub.setup("iron_ore", 10)

	func test_add_received後にCountLabelが更新される():
		hub.add_received(7)
		assert_eq(count_label.text, "7/10")


class TestHubGoalCompletion:
	extends GutTest

	var hub: Node

	func before_each():
		HubGoals.level = 1
		HubGoals.gained_rewards = {}
		hub = HUB_SCRIPT.new()
		add_child_autofree(hub)
		hub.setup("iron_ore", 3)

	func test_目標達成時にHubGoalsのlevelが増える():
		hub.add_received(3)
		assert_eq(HubGoals.level, 2)

	func test_未達成ではHubGoalsのlevelは増えない():
		hub.add_received(2)
		assert_eq(HubGoals.level, 1)

	func test_達成後にさらにadd_receivedしてもlevelは増えない():
		hub.add_received(3)
		hub.add_received(1)
		assert_eq(HubGoals.level, 2)

	func test_レベルアップ後にHubの目標アイテムが新しいレベルのものに変わる():
		hub.add_received(3)
		var new_goal = HubGoals.get_current_goal()
		assert_eq(hub.goal_item, new_goal["goal_item"])


class TestHubAcceptor:
	extends GutTest

	## Hub は自身が受け入れ口となり、何でも受け入れて
	## 目標アイテムの累計納品数を数える。

	var hub: Node

	func before_each():
		hub = HUB_SCRIPT.new()
		add_child_autofree(hub)
		hub.setup("iron_plate", 10)

	func test_can_accept_itemは常にtrueを返す():
		assert_true(hub.can_accept_item("anything"))

	func test_目標アイテムをadd_itemするとreceived_countが増える():
		hub.add_item("iron_plate", 3)
		assert_eq(hub.received_count, 3)

	func test_目標外アイテムをadd_itemしてもreceived_countは増えない():
		hub.add_item("copper", 3)
		assert_eq(hub.received_count, 0)
