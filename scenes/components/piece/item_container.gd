class_name ItemContainer
extends Node

## アイテムを格納・管理するためのコンポーネント。

signal inventory_changed

# インベントリデータ (アイテム名: 数量)
var _items: Dictionary = {}


func add_item(item_name: String, amount: int):
	if not _items.has(item_name):
		_items[item_name] = 0
	_items[item_name] += amount
	inventory_changed.emit()


func consume_item(item_name: String, amount: int):
	if _items.has(item_name):
		_items[item_name] -= amount
		if _items[item_name] <= 0:
			_items.erase(item_name)
		inventory_changed.emit()


func get_item_count(item_name: String) -> int:
	return _items.get(item_name, 0)


func get_total_item_count() -> int:
	var total = 0
	for count in _items.values():
		total += count
	return total
