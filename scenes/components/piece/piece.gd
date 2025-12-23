class_name Piece
extends Node2D

# ピースの種類ID (TetrahexShapes.TetrahexType)
var piece_type: int = -1

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

# インベントリデータ (アイテム名: 数量)
var inventory: Dictionary = {}

var processing_state: float = 0.0

@onready var inventory_label: Label = get_node_or_null("InventoryLabel")

func setup(data: Dictionary):
	if data.has("type"):
		piece_type = data["type"]
	
	if data.has("hex_coordinates"):
		hex_coordinates.clear()
		var coords = data["hex_coordinates"]
		if coords is Array:
			for h in coords:
				if h is Hex:
					hex_coordinates.append(h)

func add_item(item_name: String, amount: int):
	if not inventory.has(item_name):
		inventory[item_name] = 0
	inventory[item_name] += amount
	_update_display()

func get_item_count(item_name: String) -> int:
	return inventory.get(item_name, 0)

func _process(delta: float):
	tick(delta)

func tick(delta: float):
	# BARタイプは採掘機として振る舞う
	if piece_type == TetrahexShapes.TetrahexType.BAR:
		processing_state += delta
		if processing_state >= 1.0:
			add_item("iron", 1)
			processing_state -= 1.0

func _update_display():
	if not inventory_label:
		inventory_label = get_node_or_null("InventoryLabel")
	
	if not inventory_label:
		return
	
	var text = ""
	for item in inventory:
		text += "%s: %d\n" % [item, inventory[item]]
	inventory_label.text = text.strip_edges()