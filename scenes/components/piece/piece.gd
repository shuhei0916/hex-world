@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)

const Z_LAYER_ICONS = 1
const Z_LAYER_UI = 2
const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")

# シーンに保存されるピース定義データ（各 .tscn に直接設定する）
@export var piece_type: PieceData.Type = PieceData.Type.CONVEYOR
@export var piece_shape: Array[Vector2i] = []
@export var port_hex: Vector2i = Vector2i.ZERO
@export var port_direction: int = -1  # -1 = 出力ポートなし
@export var piece_color: Color

# 回転状態 (0-5)
var rotation_state: int = 0

# 採掘ロジック用
var processing_state: float = 0.0

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

# コンポーネント
@onready var input_storage: PieceInput = get_node_or_null("Input")
@onready var output: Output = get_node_or_null("Output")
@onready var crafter: Crafter = get_node_or_null("Crafter")
@onready var output_port: Sprite2D = get_node_or_null("OutputPort")
@onready var _speed_label: Label = get_node_or_null("SpeedLabel")
@onready var _progress_bar: ProgressBar = get_node_or_null("Crafter/ProgressBar")


func _ready():
	if Engine.is_editor_hint():
		if output_port:
			output_port.setup(get_output_ports())
		_create_hex_tiles()
		return
	if input_storage:
		input_storage.z_index = Z_LAYER_ICONS
	if output:
		output.z_index = Z_LAYER_ICONS
	if output_port:
		output_port.z_index = Z_LAYER_ICONS
	if _speed_label:
		_speed_label.z_index = Z_LAYER_UI
	if _progress_bar:
		_progress_bar.z_index = Z_LAYER_UI
	if crafter and output:
		crafter.setup(input_storage, output)


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func _create_hex_tiles():
	for child in get_children():
		if child is HexTile:
			child.queue_free()
	if piece_shape.is_empty():
		return
	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)
	for hex in get_hex_shape():
		var tile = HEX_TILE_SCENE.instantiate()
		tile.position = Layout.hex_to_pixel(layout, hex)
		add_child(tile)
		tile.setup_hex(hex)
		tile.set_color(piece_color)


func setup(rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)
	rotation_state = rotation
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if not recipes.is_empty():
		set_recipe(recipes[0])
	if output_port:
		output_port.setup(get_output_ports())
	_create_hex_tiles()


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
	var hexes: Array[Hex] = []
	for v in piece_shape:
		var hex = Hex.new(v.x, v.y, -v.x - v.y)
		for i in range(rotation_state):
			hex = Hex.rotate_right(hex)
		hexes.append(hex)
	return hexes


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	_create_hex_tiles()


func get_output_ports() -> Array:
	if port_direction < 0:
		return []
	var hex = Hex.new(port_hex.x, port_hex.y, -port_hex.x - port_hex.y)
	for i in range(rotation_state):
		hex = Hex.rotate_right(hex)
	var direction = (port_direction - rotation_state + 6) % 6
	return [{"hex": hex, "direction": direction}]


func can_accept_item(_item_name: String) -> bool:
	if not input_storage:
		return false
	return not input_storage.is_full()
