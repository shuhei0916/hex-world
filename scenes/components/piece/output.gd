class_name Output
extends Node2D

## アイテムをスタックし、接続先ピースへ搬送するコンポーネント。
## インベントリロジックは $Inventory に委譲する。

var _ejector := ItemEjector.new()
var _is_pushing: bool = false

@onready var inventory: Node2D = $Inventory


func _ready():
	inventory.inventory_changed.connect(_push_items)


func set_connected_pieces(pieces: Array) -> void:
	_ejector.connected_pieces = pieces
	try_push()


func get_connected_pieces() -> Array:
	return _ejector.connected_pieces


func add_item(item_name: String, amount: int):
	inventory.add_item(item_name, amount)


func consume_item(item_name: String, amount: int):
	inventory.consume_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	return inventory.get_item_count(item_name)


func get_total_item_count() -> int:
	return inventory.get_total_item_count()


func is_full() -> bool:
	return inventory.is_full()


func is_empty() -> bool:
	return inventory.is_empty()


func set_expected_output(item_id: String):
	inventory.expected_item = item_id
	inventory.update_visuals()


func try_push():
	_push_items()


func _push_items():
	if _is_pushing:
		return
	if inventory.is_empty() or _ejector.connected_pieces.is_empty():
		return

	_is_pushing = true
	var still_pushing = true
	while still_pushing and not inventory.is_empty():
		still_pushing = false
		for item_name in inventory.get_item_names().duplicate():
			if _ejector.try_eject(item_name):
				consume_item(item_name, 1)
				still_pushing = true
				break

	_is_pushing = false
