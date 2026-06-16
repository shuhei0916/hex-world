class_name Delivery
extends Node

var goal_item: String = ""
var goal_count: int = 0
var received_count: int = 0


func setup(item_name: String, count: int):
	goal_item = item_name
	goal_count = count


func add_received(amount: int):
	received_count += amount
	_update_label()


func is_completed() -> bool:
	return received_count >= goal_count


func _ready():
	call_deferred("_connect_to_inventory")


func _connect_to_inventory():
	var input = get_parent().get_node_or_null("ItemAcceptor")
	if input:
		input.get_node("Inventory").inventory_changed.connect(_on_inventory_changed)


func _update_label():
	var label = get_parent().get_node_or_null("GoalLabel")
	if label:
		label.text = "%s: %d/%d" % [goal_item, received_count, goal_count]


func _on_inventory_changed():
	var input = get_parent().get_node_or_null("ItemAcceptor")
	if not input:
		return
	var count = input.get_item_count(goal_item)
	if count > 0:
		input.consume_item(goal_item, count)
		add_received(count)
