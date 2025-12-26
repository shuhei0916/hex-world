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
	
	_push_items_to_neighbors()

func can_accept_item(_item_name: String) -> bool:
	# 将来的に容量制限などを入れる
	return true

func _push_items_to_neighbors():
	if inventory.is_empty():
		return
	
	var grid_manager = get_parent()
	if not grid_manager or not grid_manager.has_method("get_neighbor_piece"):
		return
		
	# インベントリのコピーを作成して反復（変更中の反復回避）
	var current_inventory = inventory.duplicate()
	
	for item_name in current_inventory:
		var count = current_inventory[item_name]
		if count <= 0:
			continue
			
		# アイテムを1つずつ配る
		# 各Hexの各方向を確認
		for hex in hex_coordinates:
			if count <= 0:
				break
				
			for direction in range(6):
				if count <= 0:
					break
					
				var neighbor = grid_manager.get_neighbor_piece(hex, direction)
				if neighbor and neighbor != self and neighbor.can_accept_item(item_name):
					# 移動処理
					neighbor.add_item(item_name, 1)
					_remove_item(item_name, 1)
					count -= 1
					# とりあえず1tickにつき1個配れたら次へ（簡易実装）
					# 実際は全方向へ均等分配などが望ましいが、まずは動くこと優先

func _remove_item(item_name: String, amount: int):
	if inventory.has(item_name):
		inventory[item_name] -= amount
		if inventory[item_name] <= 0:
			inventory.erase(item_name)
		_update_display()

func _update_display():
	if not inventory_label:
		inventory_label = get_node_or_null("InventoryLabel")
	
	if not inventory_label:
		return
	
	var text = ""
	for item in inventory:
		text += "%s: %d\n" % [item, inventory[item]]
	inventory_label.text = text.strip_edges()
