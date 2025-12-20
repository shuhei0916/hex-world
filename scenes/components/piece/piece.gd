class_name Piece
extends Node2D

# ピースの種類ID (TetrahexShapes.TetrahexType)
var piece_type: int = 0

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

# インベントリデータ (アイテム名: 数量)
var inventory: Dictionary = {}

func setup(data: Dictionary):
	if data.has("type"):
		piece_type = data["type"]
	
	if data.has("hex_coordinates"):
		# 参照渡しではなくコピーを作成して保持する
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

func _update_display():
	var label = get_node_or_null("InventoryLabel")
	if not label:
		return
	
	var text = ""
	for item in inventory:
		text += "%s: %d\n" % [item, inventory[item]]
	label.text = text.strip_edges()
