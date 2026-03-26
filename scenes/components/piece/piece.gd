class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)
signal detail_mode_changed(enabled: bool)

# ピースの種類ID (PieceData.Type)
var piece_type: int = -1

# 回転状態 (0-5)
var rotation_state: int = 0

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
@onready var input_storage: PieceInput = get_node_or_null("Input")
@onready var output: Output = get_node_or_null("Output")
@onready var crafter: Crafter = get_node_or_null("Crafter")
@onready var output_port: Sprite2D = get_node_or_null("OutputPort")


func _ready():
	if crafter and output:
		crafter.setup(input_storage, output)


func _process(delta: float):
	tick(delta)


func setup(data: PieceData, rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)

	_cached_data = data
	rotation_state = rotation

	# デフォルトレシピの適用
	if _cached_data:
		var recipes: Array[Recipe] = []
		if _cached_data.piece_type >= 0:
			recipes = Recipe.RecipeDB.get_recipes_by_type(_cached_data.piece_type as PieceData.Type)
		elif _cached_data.role != "":
			recipes = Recipe.RecipeDB.get_recipes_by_role(_cached_data.role)
		if not recipes.is_empty():
			set_recipe(recipes[0])

	if output_port:
		output_port.setup(get_output_ports())


func set_detail_mode(enabled: bool):
	is_detail_mode = enabled
	if input_storage:
		input_storage.set_detail_mode(enabled)
	if output:
		output.set_detail_mode(enabled)
	detail_mode_changed.emit(enabled)


func set_recipe(recipe: Recipe):
	if crafter:
		crafter.set_recipe(recipe)
	recipe_changed.emit(recipe)


func add_item(item_name: String, amount: int):
	if input_storage:
		input_storage.add_item(item_name, amount)


func add_to_output(item_name: String, amount: int):
	if output:
		output.add_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	var count = 0
	if input_storage:
		count += input_storage.get_item_count(item_name)
	if output:
		count += output.get_item_count(item_name)
	return count


func tick(delta: float):
	if crafter:
		crafter.tick(delta)


func get_hex_shape() -> Array[Hex]:
	if not _cached_data:
		return []

	return _cached_data.get_rotated_shape(rotation_state)


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	queue_redraw()


func get_output_ports() -> Array:
	if not _cached_data:
		return []

	return _cached_data.get_rotated_ports(rotation_state)


func can_accept_item(_item_name: String) -> bool:
	if not input_storage:
		return false
	return not input_storage.is_full()
