class_name Piece
extends Node2D

const Inventory = preload("res://scenes/components/piece/inventory.gd")

# ピースの種類ID (PieceDB.PieceType)
var piece_type: int = -1

# このピースが占有しているHex座標のリスト
var hex_coordinates: Array[Hex] = []

# 回転状態 (0-5)
var rotation_state: int = 0

# インベントリデータ (Component化)
var input_storage: Inventory
var output_storage: Inventory

# 加工ロジック用
var current_recipe: Recipe
var processing_progress: float = 0.0

# 採掘ロジック用 (BARタイプ等)
var processing_state: float = 0.0

# 転送クールダウンの更新
var transfer_rate: float = 1.0
var transfer_cooldown: float = 0.0

var count_label: Label

var is_detail_mode: bool = false

var _cached_data: PieceDB.PieceData  # キャッシュされた定義データ

@onready var status_icon: Sprite2D = get_node_or_null("StatusIcon")
@onready var progress_bar: ProgressBar = get_node_or_null("CraftingProgressBar")

@onready var input_icon: Sprite2D = get_node_or_null("InputIcon")
@onready var input_label: Label = input_icon.get_node_or_null("InputLabel") if input_icon else null
@onready var speed_label: Label = get_node_or_null("SpeedLabel")


func setup(data: Dictionary, data_override: PieceDB.PieceData = null):
	current_recipe = null
	processing_progress = 0.0

	if data_override:
		_cached_data = data_override
		if data.has("type"):
			piece_type = data["type"]
	elif data.has("type"):
		piece_type = data["type"]
		_cached_data = PieceDB.get_data(piece_type)

	# デフォルトレシピの適用
	if _cached_data:
		if _cached_data.facility_type != "":
			var recipes = Recipe.RecipeDB.get_recipes_by_facility(_cached_data.facility_type)
			if not recipes.is_empty():
				# 暫定的に最初のレシピを採用
				set_recipe(recipes[0])

	if data.has("rotation"):
		rotation_state = data["rotation"]

	if data.has("hex_coordinates"):
		hex_coordinates.clear()
		var coords = data["hex_coordinates"]
		if coords is Array:
			for h in coords:
				if h is Hex:
					hex_coordinates.append(h)

	# 初期状態は詳細モードOFF（またはGridManagerから引き継ぐ必要があるが、
	# ここではデフォルトfalseとし、GridManagerが配置後に設定することを想定）
	_update_visuals()


func _ready():
	_setup_inventories()
	count_label = status_icon.get_node_or_null("CountLabel") if status_icon else null
	_update_visuals()


func _setup_inventories():
	input_storage = Inventory.new()
	input_storage.name = "InputInventory"
	add_child(input_storage)
	input_storage.inventory_changed.connect(_update_visuals)

	output_storage = Inventory.new()
	output_storage.name = "OutputInventory"
	add_child(output_storage)
	output_storage.inventory_changed.connect(_update_visuals)


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	_update_visuals()


func set_recipe(recipe: Recipe):
	current_recipe = recipe
	processing_progress = 0.0
	_update_visuals()


func _update_visuals():
	_update_output_visuals()
	_update_input_visuals()
	_update_speed_visuals()


func _update_output_visuals():
	if not status_icon:
		return

	var item_id = ""

	# インベントリ初期化前対策
	if not input_storage or not output_storage:
		return

	# 表示すべきアイテムを決定 (Recipe Output優先)
	if current_recipe:
		# 最初の出力アイテムを代表アイコンとする
		var outputs = current_recipe.outputs.keys()
		if not outputs.is_empty():
			item_id = outputs[0]
	else:
		# レシピがない場合（Chest等）、Outputにあるものを表示
		# なければInputも含める（Chestの場合、Inputに入ったまま保持されることがあるため）
		var max_count = 0
		var all_items = []

		# Inventoryクラスのget_all_items()を使用する場合
		# (まだ実装していない場合は _items プロパティに直接アクセスするが、カプセル化のためアクセサ推奨)
		# 今回は Inventory._items は public 変数として扱われているので直接アクセス
		# TODO: Inventoryに get_all_keys() などを追加すると綺麗

		all_items.append_array(output_storage._items.keys())
		if output_storage._items.is_empty():
			all_items.append_array(input_storage._items.keys())

		for key in all_items:
			var c = get_item_count(key)
			if c > max_count:
				max_count = c
				item_id = key

	# アイコン更新
	if item_id != "":
		var item_def = ItemDB.get_item(item_id)
		if item_def:
			status_icon.texture = item_def.icon
			status_icon.visible = true

			# 数量ラベル更新 (詳細モード時のみ表示)
			if count_label:
				if is_detail_mode:
					var count = get_item_count(item_id)
					if count > 0:
						count_label.text = str(count)
						count_label.visible = true
					else:
						count_label.visible = false
				else:
					count_label.visible = false
		else:
			status_icon.visible = false
			if count_label:
				count_label.visible = false
	else:
		status_icon.visible = false
		if count_label:
			count_label.visible = false


func _update_input_visuals():
	if not input_icon or not input_label:
		return
	if not input_storage:
		return

	# 詳細モードでなければ非表示
	if not is_detail_mode:
		input_icon.visible = false
		return

	# Input Inventory の中で最も多いアイテムを表示
	var max_count = 0
	var item_id = ""

	for key in input_storage._items:
		if input_storage._items[key] > max_count:
			max_count = input_storage._items[key]
			item_id = key

	if item_id != "":
		var item_def = ItemDB.get_item(item_id)
		if item_def:
			input_icon.texture = item_def.icon
			input_icon.visible = true
			input_label.text = str(max_count)
		else:
			input_icon.visible = false
	else:
		input_icon.visible = false


func _update_speed_visuals():
	if not speed_label:
		return

	# 詳細モードでなければ非表示
	if not is_detail_mode:
		speed_label.visible = false
		return

	if current_recipe:
		if current_recipe.craft_time > 0:
			var per_min = 60.0 / current_recipe.craft_time
			speed_label.text = "%.1f/m" % per_min
			speed_label.visible = true
		else:
			speed_label.text = "Inf/m"
			speed_label.visible = true
	else:
		speed_label.visible = false


func add_item(item_name: String, amount: int):
	if input_storage:
		input_storage.add_item(item_name, amount)


func add_to_output(item_name: String, amount: int):
	if output_storage:
		output_storage.add_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	var count = 0
	if input_storage:
		count += input_storage.get_item_count(item_name)
	if output_storage:
		count += output_storage.get_item_count(item_name)
	return count


func _process(delta: float):
	tick(delta)


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	queue_redraw()


func tick(delta: float):
	# 加工ロジック (MinerもRecipeを持つようになったため統合)
	if current_recipe:
		_process_crafting(delta)
		if progress_bar:
			progress_bar.visible = processing_progress > 0
			progress_bar.max_value = current_recipe.craft_time
			progress_bar.value = processing_progress
	else:
		if progress_bar:
			progress_bar.visible = false

	# CHESTタイプはアイテムを保持するだけ（自分からは配らない）
	if piece_type == PieceDB.PieceType.CHEST:
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
	# Inputsが空の場合はtrue (Miner)
	if current_recipe.inputs.is_empty():
		return true

	if not input_storage:
		return false

	for item_name in current_recipe.inputs:
		if input_storage.get_item_count(item_name) < current_recipe.inputs[item_name]:
			return false
	return true


func _start_crafting():
	for item_name in current_recipe.inputs:
		_consume_input(item_name, current_recipe.inputs[item_name])
	processing_progress = 0.001


func _complete_crafting():
	for item_name in current_recipe.outputs:
		add_to_output(item_name, current_recipe.outputs[item_name])
	processing_progress = 0.0


func get_port_visual_params() -> Array:
	var params = []

	# Layout定義 (GridManagerと同じ設定)
	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)

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
		_draw_arrow(p.position, p.rotation, p.color, false)


func _draw_arrow(pos: Vector2, rot: float, color: Color, _is_input: bool):
	var arrow_size = 15.0
	var offset = 30.0  # ヘックスの中心からのオフセット

	draw_set_transform(pos, rot, Vector2.ONE)

	var arrow_pos = Vector2(offset, 0)
	var points = PackedVector2Array()

	# 出力矢印 (外に向かう)
	points.append(arrow_pos + Vector2(arrow_size, 0))
	points.append(arrow_pos + Vector2(0, -arrow_size / 2))
	points.append(arrow_pos + Vector2(0, arrow_size / 2))

	draw_colored_polygon(points, color)

	# トランスフォームをリセット
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func get_output_ports() -> Array:
	if not _cached_data:
		return []

	var static_ports = _cached_data.output_ports
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


func can_push_to(_target_piece: Piece, direction_to_target: int) -> bool:
	# 1. 自分の出力ポートを確認
	var has_output_port = false
	for port in get_output_ports():
		# ここでは、どのローカルhexからの出力かをまだ考慮しない（単一hexピースを想定）
		if port.direction == direction_to_target:
			has_output_port = true
			break

	if not has_output_port:
		return false

	# 緩和ルール: 相手がそこに存在すれば、Inputポートの有無に関わらず受け入れる
	return true


func can_accept_item(_item_name: String) -> bool:
	# 将来的に容量制限などを入れる
	return true


func _push_items_to_neighbors():
	if not output_storage or output_storage._items.is_empty():
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

	# TODO: Inventoryにitemsを取得するゲッターがほしいが、今は_itemsを直接参照
	# イテレーション中の変更エラーを避けるためキーを複製
	var items_to_push = output_storage._items.keys().duplicate()

	for item_name in items_to_push:
		for target in potential_targets:
			if target.can_accept_item(item_name):
				# 1つ移動して終了
				target.add_item(item_name, 1)
				_consume_output(item_name, 1)

				# クールダウンを設定
				transfer_cooldown = transfer_rate
				return  # 全体で1個移動したらこのtickの処理を終える


func _consume_input(item_name: String, amount: int):
	if input_storage:
		input_storage.consume_item(item_name, amount)


func _consume_output(item_name: String, amount: int):
	if output_storage:
		output_storage.consume_item(item_name, amount)
