class_name Output
extends Node2D

## アイテムをスタックし、接続先ピースへ搬送するコンポーネント。
## インベントリロジックは $Inventory に委譲する。

var connected_pieces: Array = []

@onready var inventory: Node2D = $Inventory


func _ready():
	inventory.inventory_changed.connect(_push_items)


func set_detail_mode(enabled: bool):
	inventory.set_detail_mode(enabled)


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


func _push_items():
	if inventory.is_empty() or connected_pieces.is_empty():
		return

	var still_pushing = true
	while still_pushing and not inventory.is_empty():
		still_pushing = false
		var items_to_push = inventory.get_item_names().duplicate()

		for item_name in items_to_push:
			for target in connected_pieces:
				if target.has_method("add_item") and target.has_method("can_accept_item"):
					if target.can_accept_item(item_name):
						target.add_item(item_name, 1)
						consume_item(item_name, 1)
						still_pushing = true
						break

			if still_pushing:
				break
