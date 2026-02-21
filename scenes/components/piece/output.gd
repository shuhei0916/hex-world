class_name Output
extends Node2D

## アイテムをスタックし、接続先ピースへ搬送するコンポーネント。

signal inventory_changed

@export var capacity: int = 20

var connected_pieces: Array = []
var is_detail_mode: bool = false

var _items: Dictionary = {}

@onready var _icon: Sprite2D = $Icon
@onready var _label: Label = $Icon/CountLabel


func _ready():
	inventory_changed.connect(update_visuals)
	inventory_changed.connect(_push_items)


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	update_visuals()


func update_visuals():
	if not _icon:
		return

	var item_id = ""
	var max_count = 0

	for key in _items:
		if _items[key] > max_count:
			max_count = _items[key]
			item_id = key

	if item_id != "":
		var item_def = ItemDB.get_item(item_id)
		if item_def:
			_icon.texture = item_def.icon
			_icon.visible = true
			if _label:
				_label.text = str(max_count)
				_label.visible = is_detail_mode
		else:
			_icon.visible = false
			if _label:
				_label.visible = false
	else:
		_icon.visible = false
		if _label:
			_label.visible = false


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


func is_full() -> bool:
	return get_total_item_count() >= capacity


func is_empty() -> bool:
	return _items.is_empty()


func _push_items():
	if _items.is_empty() or connected_pieces.is_empty():
		return

	var still_pushing = true
	while still_pushing and not _items.is_empty():
		still_pushing = false
		var items_to_push = _items.keys().duplicate()

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
