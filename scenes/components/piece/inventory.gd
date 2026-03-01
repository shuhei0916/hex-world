class_name Inventory
extends Node2D

signal inventory_changed

@export var capacity: int = 20
@export var detail_mode_only: bool = false

var is_detail_mode: bool = false
var _items: Dictionary = {}

@onready var _icon: Sprite2D = $Icon
@onready var _label: Label = $CountLabel


func _ready():
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
			_icon.visible = not detail_mode_only or is_detail_mode
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


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	update_visuals()


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


func get_item_names() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(_items.keys())
	return keys
