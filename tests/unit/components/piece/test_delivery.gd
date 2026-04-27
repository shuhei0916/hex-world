# gdlint:disable=constant-name
extends GutTest

const DELIVERY_SCRIPT = preload("res://scenes/components/piece/delivery.gd")


class TestDeliverySetup:
	extends GutTest

	var delivery: Node

	func before_each():
		delivery = DELIVERY_SCRIPT.new()
		add_child_autofree(delivery)

	func test_setup後にgoal_itemが設定される():
		delivery.setup("iron_plate", 10)
		assert_eq(delivery.goal_item, "iron_plate")

	func test_setup後にgoal_countが設定される():
		delivery.setup("iron_plate", 10)
		assert_eq(delivery.goal_count, 10)

	func test_received_countの初期値は0():
		assert_eq(delivery.received_count, 0)

	func test_add_received後にreceived_countが増える():
		delivery.add_received(1)
		assert_eq(delivery.received_count, 1)

	func test_received_countがgoal_count未満のときis_completedはfalse():
		delivery.setup("iron_plate", 10)
		delivery.add_received(5)
		assert_false(delivery.is_completed())

	func test_received_countがgoal_count以上のときis_completedはtrue():
		delivery.setup("iron_plate", 10)
		delivery.add_received(10)
		assert_true(delivery.is_completed())
