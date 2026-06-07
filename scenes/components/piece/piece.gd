@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)

const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")
const FORWARD_TEXTURE = preload("res://scenes/components/piece/forward.png")
const PORT_OFFSET = 35.0
const ARROW_COLOR = Color(0.9607843, 0.6509804, 0.13725491, 1)

# シーンに保存されるピース定義データ（各 .tscn に直接設定する）
@export var piece_type: PieceData.Type = PieceData.Type.CONVEYOR
@export var piece_shape: Array[Vector2i] = []
@export var port_hex: Vector2i = Vector2i.ZERO
@export var input_hex: Vector2i = Vector2i.ZERO
@export var port_direction: int = -1  # -1 = 出力ポートなし
@export var piece_color: Color

# 回転状態 (0-5)
var rotation_state: int = 0

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

var _output_arrow: Sprite2D = null
var _conveyor_line: Line2D = null

# コンポーネント
@onready var input_storage: PieceInput = get_node_or_null("Input")
@onready var output: Output = get_node_or_null("Output")
@onready var crafter: Crafter = get_node_or_null("Crafter")
@onready var _speed_label: Label = get_node_or_null("SpeedLabel")
@onready var _progress_bar: ProgressBar = get_node_or_null("Crafter/ProgressBar")


func _ready():
	if Engine.is_editor_hint():
		_refresh_output_arrow()
		_create_hex_tiles()
		return
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
	var layout = Layout.make_default()
	var tile_index := 0
	for hex in get_hex_shape():
		var tile = HEX_TILE_SCENE.instantiate()
		tile.position = Layout.hex_to_pixel(layout, hex)
		add_child(tile)
		move_child(tile, tile_index)
		tile_index += 1
		tile.setup_hex(hex)
		tile.set_color(piece_color)


func setup(rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)
	rotation_state = rotation
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if not recipes.is_empty():
		set_recipe(recipes[0])
	_refresh_output_arrow()
	_refresh_conveyor_line()
	_create_hex_tiles()
	_update_component_positions()


func set_recipe(recipe: Recipe):
	if crafter:
		crafter.set_recipe(recipe)
	recipe_changed.emit(recipe)


func set_output_multiplier(n: int):
	if crafter:
		crafter.output_multiplier = n
	var speed_label = get_node_or_null("SpeedLabel")
	if speed_label and speed_label.has_method("set_multiplier"):
		speed_label.set_multiplier(n)


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
	_refresh_output_arrow()
	_refresh_conveyor_line()
	_create_hex_tiles()
	_update_component_positions()


func _update_component_positions():
	var layout = Layout.make_default()
	if input_storage:
		var hex = Hex.new(input_hex.x, input_hex.y, -input_hex.x - input_hex.y)
		for i in range(rotation_state):
			hex = Hex.rotate_right(hex)
		input_storage.position = Layout.hex_to_pixel(layout, hex)


func get_output_ports() -> Array:
	if port_direction < 0:
		return []
	var hex = Hex.new(port_hex.x, port_hex.y, -port_hex.x - port_hex.y)
	for i in range(rotation_state):
		hex = Hex.rotate_right(hex)
	var direction = (port_direction - rotation_state + 6) % 6
	return [{"hex": hex, "direction": direction}]


func _refresh_conveyor_line():
	if _conveyor_line:
		_conveyor_line.queue_free()
		_conveyor_line = null
	if piece_type != PieceData.Type.CONVEYOR:
		return
	var ports = get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var output_dir = ports[0]["direction"]
	var input_dir = (output_dir + 3) % 6
	var out_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[output_dir]) * 0.5
	var in_edge = Layout.hex_to_pixel(layout, Hex.hex_directions[input_dir]) * 0.5
	_conveyor_line = Line2D.new()
	_conveyor_line.add_point(in_edge)
	_conveyor_line.add_point(Vector2.ZERO)
	_conveyor_line.add_point(out_edge)
	_conveyor_line.width = 10.0
	_conveyor_line.default_color = Color(0.9, 0.85, 0.6, 0.9)
	add_child(_conveyor_line)


func _refresh_output_arrow():
	if _output_arrow:
		_output_arrow.queue_free()
		_output_arrow = null
	if piece_type == PieceData.Type.CONVEYOR:
		return
	var ports = get_output_ports()
	if ports.is_empty():
		return
	_output_arrow = make_output_arrow(ports[0])
	add_child(_output_arrow)


func can_accept_item(_item_name: String) -> bool:
	if not input_storage:
		return false
	return not input_storage.is_full()


static func make_output_arrow(port: Dictionary) -> Sprite2D:
	var layout = Layout.make_default()
	var center_pos = Layout.hex_to_pixel(layout, port["hex"])
	var neighbor_pos = Layout.hex_to_pixel(layout, Hex.neighbor(port["hex"], port["direction"]))
	var angle = (neighbor_pos - center_pos).angle()
	var arrow = Sprite2D.new()
	arrow.texture = FORWARD_TEXTURE
	arrow.scale = Vector2(0.5, 0.5)
	arrow.modulate = ARROW_COLOR
	arrow.position = center_pos + Vector2(PORT_OFFSET, 0).rotated(angle)
	arrow.rotation = angle
	return arrow
