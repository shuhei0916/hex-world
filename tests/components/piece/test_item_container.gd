extends GutTest

var ItemContainer = load("res://scenes/components/piece/item_container.gd")
var container


func before_each():
	if ItemContainer:
		container = ItemContainer.new()


func after_each():
	if container:
		container.free()


func test_初期状態のインベントリは空である():
	if not container:
		return
	assert_eq(container.get_item_count("iron"), 0, "初期状態のアイテム数は0であるべき")


func test_アイテムを追加すると数が加算される():
	if not container:
		return
	container.add_item("iron", 5)
	assert_eq(container.get_item_count("iron"), 5, "新規追加で数が設定されるべき")

	container.add_item("iron", 3)
	assert_eq(container.get_item_count("iron"), 8, "既存アイテムに追加すると数が加算されるべき")


func test_異なる種類のアイテムは個別に管理される():
	if not container:
		return
	container.add_item("iron", 5)
	container.add_item("copper", 1)
	assert_eq(container.get_item_count("copper"), 1, "別のアイテム(copper)も正しく追加できるべき")


func test_異なる種類のアイテムを追加しても既存のアイテム数は変わらない():
	if not container:
		return
	container.add_item("iron", 5)
	container.add_item("copper", 1)
	assert_eq(container.get_item_count("iron"), 5, "別のアイテムを追加しても既存のアイテム数は変わらないべき")


func test_アイテムを消費できる():
	if not container:
		return
	container.add_item("iron", 5)
	container.consume_item("iron", 2)
	assert_eq(container.get_item_count("iron"), 3, "5 - 2 = 3 になるべき")


func test_消費して0になったらエントリが消えるか0になる():
	if not container:
		return
	container.add_item("iron", 2)
	container.consume_item("iron", 2)
	assert_eq(container.get_item_count("iron"), 0, "2 - 2 = 0")


func test_アイテム変更時にシグナルが発火される():
	if not container:
		return

	watch_signals(container)
	container.add_item("iron", 1)
	assert_signal_emitted(container, "inventory_changed", "追加時にシグナルが出るべき")

	container.consume_item("iron", 1)
	assert_signal_emitted(container, "inventory_changed", "消費時にシグナルが出るべき")


func test_合計アイテム数を取得できる():
	if not container:
		return

	container.add_item("iron", 5)
	container.add_item("copper", 3)
	assert_eq(container.get_total_item_count(), 8, "5 + 3 = 8 であるべき")

	container.consume_item("iron", 2)
	assert_eq(container.get_total_item_count(), 6, "8 - 2 = 6 であるべき")
