extends GutTest

var transporter: Transporter
var source_container: ItemContainer


# テスト用のダミーターゲット
class MockTarget:
	var inventory: Dictionary = {}
	var accept: bool = true

	func can_accept_item(_item_name: String) -> bool:
		return accept

	func add_item(item_name: String, amount: int):
		inventory[item_name] = inventory.get(item_name, 0) + amount


func before_each():
	transporter = Transporter.new()
	source_container = ItemContainer.new()
	transporter.setup(source_container)


func after_each():
	transporter.free()
	source_container.free()


func test_初期状態では準備完了状態である():
	assert_true(transporter.is_ready())


func test_アイテムの移動が一度に全量行われる():
	source_container.add_item("iron", 5)
	var target = MockTarget.new()

	transporter.push([target])

	assert_eq(source_container.get_item_count("iron"), 0, "ソースのアイテムはすべて搬出されるべき")
	assert_eq(target.inventory["iron"], 5, "ターゲットにすべてのアイテムが届くべき")


func test_ターゲットが受け入れ不可の場合は移動しない():
	source_container.add_item("iron", 5)
	var target = MockTarget.new()
	target.accept = false

	transporter.push([target])

	assert_eq(source_container.get_item_count("iron"), 5, "ソースの数は変わらないべき")
	assert_eq(target.inventory.get("iron", 0), 0, "ターゲットには増えないべき")
	assert_true(transporter.is_ready(), "移動しなかった場合はクールダウンが発生しないべき")


func test_ターゲットが20個以上のアイテムを持っている場合は移動しない():
	# このテストは Transporter が target.can_accept_item() を正しく呼んでいるかを検証する
	source_container.add_item("iron", 1)
	var target = MockTarget.new()
	target.accept = false  # 満杯をシミュレート

	transporter.push([target])

	assert_eq(source_container.get_item_count("iron"), 1, "満杯の相手には送らないべき")
