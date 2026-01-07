class_name Piece
extends Node2D

# ピースの種類ID (TetrahexShapes.TetrahexType)
var piece_type: int = -1

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

# 回転状態 (0-5)
var rotation_state: int = 0

# インベントリデータ (アイテム名: 数量)
var inventory: Dictionary = {}

var processing_state: float = 0.0
# 転送レート (秒/個)
var transfer_rate: float = 1.0
var transfer_cooldown: float = 0.0

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

func rotate_cw():
	rotation_state = (rotation_state + 1) % 6

func tick(delta: float):
	# BARタイプは採掘機として振る舞う
	if piece_type == TetrahexShapes.TetrahexType.BAR:
		processing_state += delta
		if processing_state >= 1.0:
			add_item("iron", 1)
			processing_state -= 1.0
	
	# CHESTタイプはアイテムを保持するだけ（自分からは配らない）
	if piece_type == TetrahexShapes.TetrahexType.CHEST:
		return
	
	# 転送クールダウンの更新
	if transfer_cooldown > 0:
		transfer_cooldown -= delta
	
	if transfer_cooldown <= 0:
		_push_items_to_neighbors()

func get_input_ports() -> Array:
	if piece_type == -1 or not TetrahexShapes.TetrahexData.definitions.has(piece_type):
		return []
	
	var static_ports = TetrahexShapes.TetrahexData.definitions[piece_type].input_ports
	return _get_rotated_ports(static_ports)

func get_output_ports() -> Array:
	if piece_type == -1 or not TetrahexShapes.TetrahexData.definitions.has(piece_type):
		return []
	
	var static_ports = TetrahexShapes.TetrahexData.definitions[piece_type].output_ports
	return _get_rotated_ports(static_ports)

func _get_rotated_ports(ports: Array) -> Array:
	var rotated_ports: Array = []
	for port_def in ports:
		var rotated_hex = port_def.hex
		for i in range(rotation_state):
			rotated_hex = Hex.rotate_right(rotated_hex)
		
		var rotated_direction = (port_def.direction + rotation_state) % 6
		rotated_ports.append({"hex": rotated_hex, "direction": rotated_direction})
		
	return rotated_ports

func can_push_to(target_piece: Piece, direction_to_target: int) -> bool:
	# 1. 自分の出力ポートを確認
	var has_output_port = false
	for port in get_output_ports():
		# ここでは、どのローカルhexからの出力かをまだ考慮しない（単一hexピースを想定）
		if port.direction == direction_to_target:
			has_output_port = true
			break
	
	if not has_output_port:
		return false
		
	# 2. 相手の入力ポートを確認
	var opposite_direction = (direction_to_target + 3) % 6
	var has_input_port = false
	for port in target_piece.get_input_ports():
		if port.direction == opposite_direction:
			has_input_port = true
			break
			
	return has_input_port

func can_accept_item(_item_name: String) -> bool:
	# 将来的に容量制限などを入れる
	return true

func _push_items_to_neighbors():
	if inventory.is_empty():
		return
	
	var grid_manager = get_parent()
	if not grid_manager or not grid_manager.has_method("get_neighbor_piece"):
		return
	
	# 送信可能な隣接ピースをユニークに収集
	var potential_targets: Array[Piece] = []
	for hex in hex_coordinates:
		for direction in range(6):
			var neighbor = grid_manager.get_neighbor_piece(hex, direction)
			if neighbor and neighbor != self and not neighbor in potential_targets:
				# 接続可能かチェック
				if can_push_to(neighbor, direction):
					potential_targets.append(neighbor)
	
	for item_name in inventory:
		for target in potential_targets:
			if target.can_accept_item(item_name):
				# 1つ移動して終了
				target.add_item(item_name, 1)
				_remove_item(item_name, 1)
				
				# クールダウンを設定
				transfer_cooldown = transfer_rate
				return # 全体で1個移動したらこのtickの処理を終える

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
