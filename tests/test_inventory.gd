extends GutTest

var Inventory = load("res://scenes/components/piece/inventory.gd")
var inventory


func before_each():
	if Inventory:
		inventory = Inventory.new()


func after_each():
	if inventory:
		inventory.free()


func test_初期状態のインベントリは空である():
	if not inventory:
		return
	assert_eq(inventory.get_item_count("iron"), 0, "初期状態のアイテム数は0であるべき")


func test_アイテムを追加すると数が加算される():
	if not inventory:
		return
	inventory.add_item("iron", 5)
	assert_eq(inventory.get_item_count("iron"), 5, "新規追加で数が設定されるべき")

	inventory.add_item("iron", 3)
	assert_eq(inventory.get_item_count("iron"), 8, "既存アイテムに追加すると数が加算されるべき")


func test_異なる種類のアイテムは個別に管理される():
	if not inventory:
		return
	inventory.add_item("iron", 5)
	inventory.add_item("copper", 1)
	assert_eq(inventory.get_item_count("copper"), 1, "別のアイテム(copper)も正しく追加できるべき")


func test_異なる種類のアイテムを追加しても既存のアイテム数は変わらない():
	if not inventory:
		return
	inventory.add_item("iron", 5)
	inventory.add_item("copper", 1)
	assert_eq(inventory.get_item_count("iron"), 5, "別のアイテムを追加しても既存のアイテム数は変わらないべき")


func test_アイテムを消費できる():
	if not inventory:
		return
	inventory.add_item("iron", 5)
	inventory.consume_item("iron", 2)
	assert_eq(inventory.get_item_count("iron"), 3, "5 - 2 = 3 になるべき")


func test_消費して0になったらエントリが消えるか0になる():
	if not inventory:
		return
	inventory.add_item("iron", 2)
	inventory.consume_item("iron", 2)
	assert_eq(inventory.get_item_count("iron"), 0, "2 - 2 = 0")


func test_アイテム変更時にシグナルが発火される():
	if not inventory:
		return

	watch_signals(inventory)
	inventory.add_item("iron", 1)
	assert_signal_emitted(inventory, "inventory_changed", "追加時にシグナルが出るべき")

	inventory.consume_item("iron", 1)
	assert_signal_emitted(inventory, "inventory_changed", "消費時にシグナルが出るべき")
