class_name Piece
extends Node2D

const ARROW_TEXTURE = preload("res://scenes/components/piece/forward.png")

# ピースの種類ID (PieceData.Type)
var piece_type: int = -1

# 回転状態 (0-5)
var rotation_state: int = 0

# トポロジー情報 (Managerによって管理される)
var destinations: Array[Piece] = []

# 採掘ロジック用 (BARタイプ等)
var processing_state: float = 0.0

var is_detail_mode: bool = false

# プロパティアクセサ
var current_recipe: Recipe:
	get:
		return crafter.current_recipe if crafter else null

var processing_progress: float:
	get:
		return crafter.processing_progress if crafter else 0.0
	set(value):
		if crafter:
			crafter.processing_progress = value

var _cached_data: PieceData  # キャッシュされた定義データ

# コンポーネント
@onready var input_storage: ItemContainer = get_node_or_null("InputInventory")
@onready var output_storage: ItemContainer = get_node_or_null("OutputInventory")
@onready var crafter: Crafter = get_node_or_null("Crafter")
@onready var transporter: Transporter = get_node_or_null("Transporter")

@onready var progress_bar: ProgressBar = get_node_or_null("CraftingProgressBar")
@onready var speed_label: Label = get_node_or_null("SpeedLabel")


func _ready():
	# PIECE_SCENE.instantiate() で呼ばれた場合、@onready 済みのノードをセットアップ
	if crafter and input_storage and output_storage:
		crafter.setup(input_storage, output_storage)
	if transporter and output_storage:
		transporter.setup(output_storage)

	_update_visuals()


func _process(delta: float):
	tick(delta)


func setup(data: PieceData, rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)

	_cached_data = data
	rotation_state = rotation

	# デフォルトレシピの適用
	if _cached_data:
		if _cached_data.role != "":
			var recipes = Recipe.RecipeDB.get_recipes_by_role(_cached_data.role)
			if not recipes.is_empty():
				# 暫定的に最初のレシピを採用
				set_recipe(recipes[0])

	_update_visuals()
	_update_arrow_visuals()


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	if input_storage:
		input_storage.set_detail_mode(enabled)
	if output_storage:
		output_storage.set_detail_mode(enabled)
	_update_visuals()


func set_recipe(recipe: Recipe):
	if crafter:
		crafter.set_recipe(recipe)
	_update_visuals()


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


func tick(delta: float):
	if crafter:
		crafter.tick(delta)

	if current_recipe:
		if progress_bar:
			progress_bar.visible = processing_progress > 0
			progress_bar.max_value = current_recipe.craft_time
			progress_bar.value = processing_progress
	else:
		if progress_bar:
			progress_bar.visible = false

	if _cached_data and _cached_data.role == "storage":
		return


func get_hex_shape() -> Array[Hex]:
	if not _cached_data:
		return []

	return _cached_data.get_rotated_shape(rotation_state)


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	queue_redraw()


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


func get_output_ports() -> Array:
	if not _cached_data:
		return []

	return _cached_data.get_rotated_ports(rotation_state)


func can_accept_item(_item_name: String) -> bool:
	if not input_storage:
		return false
	return not input_storage.is_full()


# --- Private Methods ---


func _update_visuals():
	_update_speed_visuals()


func _update_arrow_visuals():
	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)
	var ports = get_output_ports()
	var offset_dist = 35.0

	# NOTE: portsが複数の場合は未対応なので注意
	for i in range(ports.size()):
		var port = ports[i]

		var arrow = $OutputPort

		var center_pos = Layout.hex_to_pixel(layout, port.hex)
		var neighbor_hex = Hex.neighbor(port.hex, port.direction)
		var neighbor_pos = Layout.hex_to_pixel(layout, neighbor_hex)
		var angle = (neighbor_pos - center_pos).angle()

		arrow.position = center_pos + Vector2(offset_dist, 0).rotated(angle)
		arrow.rotation = angle


func _update_speed_visuals():
	if not speed_label:
		return

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


func _push_items():
	if not output_storage or output_storage._items.is_empty():
		return

	if transporter and not destinations.is_empty():
		transporter.push(destinations)
