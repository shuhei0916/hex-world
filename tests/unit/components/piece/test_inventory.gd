# gdlint:disable=constant-name
extends GutTest

const InventoryScript = preload("res://scenes/components/piece/inventory.gd")
const InventoryScene = preload("res://scenes/components/piece/inventory.tscn")


class TestInventoryData:
	extends GutTest

	var inv

	func before_each():
		inv = InventoryScript.new()

	func after_each():
		if is_instance_valid(inv):
			inv.free()

	func test_初期状態のインベントリは空である():
		assert_eq(inv.get_item_count("iron_ore"), 0)

	func test_アイテムを追加できる():
		inv.add_item("iron_ore", 5)
		assert_eq(inv.get_item_count("iron_ore"), 5)

	func test_既存アイテムに追加すると数が加算される():
		inv.add_item("iron_ore", 5)
		inv.add_item("iron_ore", 3)
		assert_eq(inv.get_item_count("iron_ore"), 8)

	func test_アイテムを消費できる():
		inv.add_item("iron_ore", 5)
		inv.consume_item("iron_ore", 2)
		assert_eq(inv.get_item_count("iron_ore"), 3)

	func test_消費して0になったらエントリが消える():
		inv.add_item("iron_ore", 2)
		inv.consume_item("iron_ore", 2)
		assert_eq(inv.get_item_count("iron_ore"), 0)

	func test_合計アイテム数を取得できる():
		inv.add_item("iron_ore", 5)
		inv.add_item("iron_ingot", 3)
		assert_eq(inv.get_total_item_count(), 8)

	func test_is_fullで満杯を判定できる():
		inv.add_item("iron_ore", 20)
		assert_true(inv.is_full())

	func test_is_emptyで空を判定できる():
		assert_true(inv.is_empty())

	func test_アイテム追加時にシグナルが発火される():
		watch_signals(inv)
		inv.add_item("iron_ore", 1)
		assert_signal_emitted(inv, "inventory_changed")


class TestInventoryVisuals:
	extends GutTest

	var inv

	func before_each():
		inv = InventoryScene.instantiate()
		add_child_autofree(inv)

	func test_アイテムがある場合Iconが表示される():
		inv.add_item("iron_ore", 1)
		assert_true(inv.get_node("Icon").visible)

	func test_アイテムがない場合Iconが非表示になる():
		assert_false(inv.get_node("Icon").visible)

	func test_detail_modeがfalseの場合CountLabelが非表示():
		inv.add_item("iron_ore", 1)
		assert_false(inv.get_node("CountLabel").visible)

	func test_detail_modeがtrueの場合CountLabelが表示される():
		inv.add_item("iron_ore", 1)
		inv.set_detail_mode(true)
		assert_true(inv.get_node("CountLabel").visible)

	func test_detail_mode_onlyがtrueかつdetail_modeがfalseの場合Iconが非表示():
		inv.detail_mode_only = true
		inv.add_item("iron_ore", 1)
		assert_false(inv.get_node("Icon").visible)

	func test_detail_mode_onlyがtrueかつdetail_modeがtrueでアイテムありの場合Iconが表示():
		inv.detail_mode_only = true
		inv.set_detail_mode(true)
		inv.add_item("iron_ore", 1)
		assert_true(inv.get_node("Icon").visible)
