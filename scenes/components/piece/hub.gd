class_name Hub
extends Node

## 納品ゾーン（shapez の hub 相当）。接続元の ItemEjector から届いたアイテムを
## 自身が受け入れ口（acceptor）として受け取り、目標アイテムの累計納品数を数える。
## 容量無限の累計カウンタなので何でも受け入れる（goal 以外は数えず破棄）。

var goal_item: String = ""
var goal_count: int = 0
var received_count: int = 0


func setup(item_name: String, count: int):
	goal_item = item_name
	goal_count = count
	_update_label()


# --- 受け入れ口（acceptor インターフェース） ---
func can_accept_item(_item_name: String) -> bool:
	return true


func add_item(item_name: String, amount: int):
	if item_name == goal_item:
		add_received(amount)


func add_received(amount: int):
	received_count += amount
	_update_label()


func is_completed() -> bool:
	return received_count >= goal_count


func _update_label():
	var label = get_parent().get_node_or_null("GoalLabel")
	if label:
		label.text = "%s: %d/%d" % [goal_item, received_count, goal_count]
