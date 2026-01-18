extends Node


class ItemDefinition:
	var id: String
	var display_name: String
	var icon: Texture2D

	func _init(id_val: String, name_val: String, icon_val: Texture2D):
		id = id_val
		display_name = name_val
		icon = icon_val


var _items = {}


func _ready():
	_register_defaults()


func _register_defaults():
	register_item(
		ItemDefinition.new("iron_ore", "Iron Ore", load("res://assets/items/iron_ore.png"))
	)
	register_item(
		ItemDefinition.new("iron_ingot", "Iron Ingot", load("res://assets/items/iron_ingot.png"))
	)
	register_item(
		ItemDefinition.new("iron_plate", "Iron Plate", load("res://assets/items/iron_plate.png"))
	)


func register_item(item: ItemDefinition):
	_items[item.id] = item


func get_item(id: String) -> ItemDefinition:
	return _items.get(id)
