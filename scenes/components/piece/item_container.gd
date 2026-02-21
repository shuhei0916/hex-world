class_name ItemContainer
extends Node2D

## アイテムを格納・管理するためのコンポーネント。

signal inventory_changed

# true の場合、detail_mode が ON の時だけアイコンを表示する（Input 側用）
# false の場合、アイテムがあれば常時アイコンを表示する（Output 側用）
@export var detail_mode_only: bool = false

# 最大容量 (合計アイテム数)
var capacity: int = 20

var is_detail_mode: bool = false

# インベントリデータ (アイテム名: 数量)
var _items: Dictionary = {}

@onready var _icon: Sprite2D = _find_child_by_type("Sprite2D")
@onready var _label: Label = _find_child_by_type("Label", _icon)


func _ready():
	inventory_changed.connect(update_visuals)


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	update_visuals()


func update_visuals():
	if not _icon:
		return

	var item_id = ""
	var max_count = 0

	# もっとも数が多いアイテムを表示（暫定）
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


func _find_child_by_type(type_name: String, parent_node: Node = self) -> Node:
	for child in parent_node.get_children():
		if child.is_class(type_name) or child.get_class() == type_name:
			return child
		var res = _find_child_by_type(type_name, child)
		if res:
			return res
	return null
