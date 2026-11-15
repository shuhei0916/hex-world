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
	# [id, 表示名]。アイコンは tools/generate_item_icons.py が作る記号的な線画（assets/items/<id>.svg）。
	# 並びは docs/recipe_plan.md の段階順（原料 → 段階1 → 段階2 → 段階3）
	for entry in [
		["iron_ore", "Iron Ore"],
		["copper_ore", "Copper Ore"],
		["coal", "Coal"],
		["sand", "Sand"],
		["iron_ingot", "Iron Ingot"],
		["iron_plate", "Iron Plate"],
		["screw", "Screw"],
		["gear", "Gear"],
		["copper_ingot", "Copper Ingot"],
		["copper_wire", "Copper Wire"],
		["glass", "Glass"],
		["steel", "Steel"],
		["steel_beam", "Steel Beam"],
		["circuit", "Circuit"],
		["motor", "Motor"],
		["lens", "Lens"],
		["frame", "Frame"],
		["sensor", "Sensor"],
		["engine", "Engine"],
		["probe", "Probe"],
	]:
		var icon = load("res://assets/items/%s.svg" % entry[0])
		register_item(ItemDefinition.new(entry[0], entry[1], icon))


func register_item(item: ItemDefinition):
	_items[item.id] = item


# 登録済みのアイテムの id（登録順）
func all_ids() -> Array:
	return _items.keys()


func get_item(id: String) -> ItemDefinition:
	return _items.get(id)
