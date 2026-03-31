@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)

const FORWARD_TEXTURE = preload("res://scenes/components/piece/forward.png")

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


func _ready():
	if Engine.is_editor_hint():
		if output_port:
			output_port.setup(get_output_ports())
		queue_redraw()
		return
	if crafter and output:
		crafter.setup(input_storage, output)


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func _draw():
	if not Engine.is_editor_hint():
		return
	if piece_shape.is_empty():
		return
	var layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2.ZERO)
	for v in piece_shape:
		var hex = Hex.new(v.x, v.y, -v.x - v.y)
		var corners = _get_hex_corners(layout, hex)
		var is_pivot = v.x == 0 and v.y == 0
		var fill = Color(piece_color.r, piece_color.g, piece_color.b, 0.55)
		draw_polygon(corners, [fill])
		var outline_color = Color.WHITE if is_pivot else Color(1.0, 1.0, 1.0, 0.4)
		var outline = PackedVector2Array(corners)
		outline.append(corners[0])
		draw_polyline(outline, outline_color, 2.0 if is_pivot else 1.0)
	var pivot_px = Layout.hex_to_pixel(layout, Hex.new(0, 0))
	draw_circle(pivot_px, 5.0, Color.WHITE)
	if port_direction >= 0:
		_draw_output_port(layout)


func _get_hex_corners(layout: Layout, hex: Hex) -> PackedVector2Array:
	var center = Layout.hex_to_pixel(layout, hex)
	var pts = PackedVector2Array()
	for i in 6:
		var angle_rad = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(angle_rad), sin(angle_rad)) * layout.size.x)
	return pts


func _draw_output_port(layout: Layout):
	var hex = Hex.new(port_hex.x, port_hex.y, -port_hex.x - port_hex.y)
	var port_px = Layout.hex_to_pixel(layout, hex)
	var neighbor = Hex.add(hex, Hex.hex_directions[port_direction])
	var neighbor_px = Layout.hex_to_pixel(layout, neighbor)
	var angle = (neighbor_px - port_px).angle()
	var pos = port_px + Vector2(35.0, 0).rotated(angle)
	var half = FORWARD_TEXTURE.get_size() / 2.0
	draw_set_transform(pos, angle, Vector2(0.5, 0.5))
	draw_texture(FORWARD_TEXTURE, -half, Color(0.9607843, 0.6509804, 0.13725491, 1))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func setup(rotation: int = 0):
	if crafter:
		crafter.set_recipe(null)
	rotation_state = rotation
	var recipes = Recipe.RecipeDB.get_recipes_by_type(piece_type)
	if not recipes.is_empty():
		set_recipe(recipes[0])
	if output_port:
		output_port.setup(get_output_ports())


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
	queue_redraw()


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
