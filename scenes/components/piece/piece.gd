class_name Piece
extends Node2D

# ピースの種類ID (PieceShapes.PieceType)
var piece_type: int = -1

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

# 回転状態 (0-5)
var rotation_state: int = 0

# インベントリデータ (アイテム名: 数量)
var inventory: Dictionary = {}

# 加工ロジック用
var current_recipe: Recipe
var processing_progress: float = 0.0

# 採掘ロジック用 (BARタイプ等)
var processing_state: float = 0.0

# 転送レート (秒/個)
var transfer_rate: float = 1.0
var transfer_cooldown: float = 0.0

@onready var inventory_label: Label = get_node_or_null("InventoryLabel")


func setup(data: Dictionary):
	current_recipe = null
	processing_progress = 0.0

	if data.has("type"):
		piece_type = data["type"]

		# デフォルトレシピの適用
		if PieceShapes.PieceData.definitions.has(piece_type):
			var def = PieceShapes.PieceData.definitions[piece_type]
			if def.default_recipe_id != "":
				var recipe = Recipe.RecipeDB.get_recipe(def.default_recipe_id)
				if recipe:
					set_recipe(recipe)

	if data.has("rotation"):
		rotation_state = data["rotation"]

	if data.has("hex_coordinates"):
		hex_coordinates.clear()
		var coords = data["hex_coordinates"]
		if coords is Array:
			for h in coords:
				if h is Hex:
					hex_coordinates.append(h)


func set_recipe(recipe: Recipe):
	current_recipe = recipe
	processing_progress = 0.0


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
	queue_redraw()


func tick(delta: float):
	# BARタイプは採掘機として振る舞う
	if piece_type == PieceShapes.PieceType.BAR:
		processing_state += delta
		if processing_state >= 1.0:
			add_item("iron_ore", 1)
			processing_state -= 1.0

	# 加工ロジック
	if current_recipe:
		_process_crafting(delta)

	# CHESTタイプはアイテムを保持するだけ（自分からは配らない）
	if piece_type == PieceShapes.PieceType.CHEST:
		return

	# 転送クールダウンの更新
	if transfer_cooldown > 0:
		transfer_cooldown -= delta

	if transfer_cooldown <= 0:
		_push_items_to_neighbors()


func _process_crafting(delta: float):
	# 未開始なら開始を試みる
	if processing_progress == 0.0:
		if _can_start_crafting():
			_start_crafting()

	# 加工中なら進捗を進める
	if processing_progress > 0.0:
		processing_progress += delta
		if processing_progress >= current_recipe.craft_time:
			_complete_crafting()


func _can_start_crafting() -> bool:
	if not current_recipe:
		return false
	for item_name in current_recipe.inputs:
		if get_item_count(item_name) < current_recipe.inputs[item_name]:
			return false
	return true


func _start_crafting():
	for item_name in current_recipe.inputs:
		_remove_item(item_name, current_recipe.inputs[item_name])
	processing_progress = 0.001


func _complete_crafting():
	for item_name in current_recipe.outputs:
		add_item(item_name, current_recipe.outputs[item_name])
	processing_progress = 0.0


func get_port_visual_params() -> Array:
	var params = []

	# Layout定義 (GridManagerと同じ設定)
	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)

	# 入力ポート (青系)
	for port in get_input_ports():
		var center_pos = Layout.hex_to_pixel(layout, port.hex)
		var neighbor_hex = Hex.neighbor(port.hex, port.direction)
		var neighbor_pos = Layout.hex_to_pixel(layout, neighbor_hex)
		var angle = (neighbor_pos - center_pos).angle()

		params.append(
			{"position": center_pos, "rotation": angle, "type": "in", "color": Color("#4A90E2")}  # 明るい青
		)

	# 出力ポート (オレンジ系)
	for port in get_output_ports():
		var center_pos = Layout.hex_to_pixel(layout, port.hex)
		var neighbor_hex = Hex.neighbor(port.hex, port.direction)
		var neighbor_pos = Layout.hex_to_pixel(layout, neighbor_hex)
		var angle = (neighbor_pos - center_pos).angle()

		params.append(
			{"position": center_pos, "rotation": angle, "type": "out", "color": Color("#F5A623")}  # 明るいオレンジ
		)

	return params


func _draw():
	var params = get_port_visual_params()
	for p in params:
		_draw_arrow(p.position, p.rotation, p.color, p.type == "in")


func _draw_arrow(pos: Vector2, rot: float, color: Color, is_input: bool):
	var arrow_size = 15.0
	var offset = 30.0  # ヘックスの中心からのオフセット

	draw_set_transform(pos, rot, Vector2.ONE)

	var arrow_pos = Vector2(offset, 0)
	var points = PackedVector2Array()

	if is_input:
		# 入力矢印 (中心に向かう)
		points.append(arrow_pos + Vector2(0, 0))
		points.append(arrow_pos + Vector2(arrow_size, -arrow_size / 2))
		points.append(arrow_pos + Vector2(arrow_size, arrow_size / 2))
	else:
		# 出力矢印 (外に向かう)
		points.append(arrow_pos + Vector2(arrow_size, 0))
		points.append(arrow_pos + Vector2(0, -arrow_size / 2))
		points.append(arrow_pos + Vector2(0, arrow_size / 2))

	draw_colored_polygon(points, color)

	# トランスフォームをリセット
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func get_input_ports() -> Array:
	if piece_type == -1 or not PieceShapes.PieceData.definitions.has(piece_type):
		return []

	var static_ports = PieceShapes.PieceData.definitions[piece_type].input_ports
	return _get_rotated_ports(static_ports)


func get_output_ports() -> Array:
	if piece_type == -1 or not PieceShapes.PieceData.definitions.has(piece_type):
		return []

	var static_ports = PieceShapes.PieceData.definitions[piece_type].output_ports
	return _get_rotated_ports(static_ports)


func _get_rotated_ports(ports: Array) -> Array:
	var rotated_ports: Array = []
	for port_def in ports:
		var rotated_hex = port_def.hex
		for i in range(rotation_state):
			rotated_hex = Hex.rotate_right(rotated_hex)

		# 時計回り(CW)なので、方向インデックスは減る (0->5->4...)
		var rotated_direction = (port_def.direction - rotation_state + 6) % 6
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
				return  # 全体で1個移動したらこのtickの処理を終える


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
