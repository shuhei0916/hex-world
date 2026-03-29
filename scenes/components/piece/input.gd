class_name PieceInput
extends Node2D

## 外部からのアイテム受け入れコンポーネント。
## インベントリロジックは $Inventory に委譲する。

@onready var inventory: Node2D = $Inventory


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
