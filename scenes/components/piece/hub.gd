class_name Hub
extends Node

## 納品ゾーン（shapez の hub 相当）。接続元の ItemEjector から届いたアイテムを
## 自身が受け入れ口（acceptor）として受け取り、目標アイテムの累計納品数を数える。
## 容量無限の累計カウンタなので何でも受け入れる（goal 以外は数えず破棄）。

var goal_item: String = ""
var goal_count: int = 0
var received_count: int = 0
var _completed: bool = false


func _ready():
	HubGoals.level_up.connect(_on_level_up)


func setup(item_name: String, count: int):
	goal_item = item_name
	goal_count = count
	received_count = 0
	_completed = false
	_update_display()


func _on_level_up(_new_level: int, _reward: String):
	var goal = HubGoals.get_current_goal()
	setup(goal["goal_item"], goal["required"])


# --- 受け入れ口（acceptor インターフェース） ---
func can_accept_item(_item_name: String) -> bool:
	return true


func add_item(item_name: String, amount: int):
	if item_name == goal_item:
		add_received(amount)


func add_received(amount: int):
	if _completed:
		return
	received_count += amount
	_update_display()
	if is_completed():
		_completed = true
		HubGoals.advance_level()


func is_completed() -> bool:
	return received_count >= goal_count


func _update_display():
	var parent = get_parent()
	if not parent:
		return
	var icon = parent.get_node_or_null("GoalIcon")
	if icon:
		var item_def = ItemDB.get_item(goal_item)
		icon.texture = item_def.icon if item_def else null
	var label = parent.get_node_or_null("CountLabel")
	if label:
		label.text = "%d/%d" % [received_count, goal_count]
