@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)
signal shape_changed

const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")
const FORWARD_TEXTURE = preload("res://scenes/components/piece/forward.png")
const PORT_OFFSET = 35.0
const ARROW_COLOR = Color(0.9607843, 0.6509804, 0.13725491, 1)

# シーンに保存されるピース定義データ（各 .tscn に直接設定する）
@export var piece_type: PieceData.Type = PieceData.Type.CONVEYOR
@export var piece_shape: Array[Vector2i] = []
@export var port_hex: Vector2i = Vector2i.ZERO
@export var port_hex2: Vector2i = Vector2i.ZERO
@export var port_direction: int = -1  # -1 = 出力ポートなし
@export var port_direction2: int = -1  # -1 = 第2出力なし
@export var piece_color: Color

# 回転状態 (0-5)
var rotation_state: int = 0

# プロパティアクセサ
var current_recipe: Recipe:
	get:
		return crafter.current_recipe if crafter else null

var _output_arrow: Sprite2D = null
var _output_arrow2: Sprite2D = null

# コンポーネント
@onready var input_storage: PieceInput = get_node_or_null("Input")
@onready var output: Output = get_node_or_null("Output")
@onready var crafter: Crafter = get_node_or_null("Crafter")


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
	_create_hex_tiles()
	_update_component_positions()
	shape_changed.emit()


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
	var acceptor = get_acceptor()
	if acceptor:
		acceptor.add_item(item_name, amount)


func add_to_output(item_name: String, amount: int):
	if output:
		output.add_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	var count = 0
	for child in get_children():
		if child.has_method("get_item_count"):
			count += child.get_item_count(item_name)
	return count


func tick(delta: float):
	if crafter:
		crafter.tick(delta)


func get_hex_shape() -> Array[Hex]:
	var hexes: Array[Hex] = []
	for v in piece_shape:
		hexes.append(Hex.from_offset_rotated(v, rotation_state))
	return hexes


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	_refresh_output_arrow()
	_create_hex_tiles()
	_update_component_positions()
	shape_changed.emit()


func _update_component_positions():
	# 出力アイテムをポート端に「はみ出し」表示する（shapez の抽出器ルック）
	if not output:
		return
	var ports = get_output_ports()
	if ports.is_empty():
		return
	var layout = Layout.make_default()
	var port = ports[0]
	var hex_pos = Layout.hex_to_pixel(layout, port.hex)
	var edge = Layout.hex_to_pixel(layout, Hex.hex_directions[port.direction]) * 0.5
	output.position = hex_pos + edge
	# ヘックスタイル（z_index=0）より奥に描画し、タイルを手前に見せる
	output.z_index = -1


func get_output_ports() -> Array:
	var ports = []
	if port_direction >= 0:
		ports.append(_make_port(port_hex, port_direction))
	if port_direction2 >= 0:
		ports.append(_make_port(port_hex2, port_direction2))
	return ports


func _make_port(offset: Vector2i, direction: int) -> Dictionary:
	var hex = Hex.from_offset_rotated(offset, rotation_state)
	var rotated_direction = (direction - rotation_state + 6) % 6
	return {"hex": hex, "direction": rotated_direction}


func _refresh_output_arrow():
	if _output_arrow:
		_output_arrow.queue_free()
		_output_arrow = null
	if _output_arrow2:
		_output_arrow2.queue_free()
		_output_arrow2 = null
	var ports = get_output_ports()
	if ports.is_empty():
		return
	_output_arrow = make_output_arrow(ports[0])
	add_child(_output_arrow)
	if ports.size() > 1:
		_output_arrow2 = make_output_arrow(ports[1])
		add_child(_output_arrow2)


func get_acceptor() -> Node:
	# アイテム受け入れ口となるコンポーネント（shapez の ItemAcceptor 相当）を返す
	for child in get_children():
		if child.has_method("can_accept_item") and child.has_method("add_item"):
			return child
	return null


func can_accept_item(item_name: String) -> bool:
	var acceptor = get_acceptor()
	return acceptor != null and acceptor.can_accept_item(item_name)


func set_connected_pieces(pieces: Array) -> void:
	for child in get_children():
		if child.has_method("set_connected_pieces"):
			child.set_connected_pieces(pieces)
			return


func get_connected_pieces() -> Array:
	for child in get_children():
		if child.has_method("get_connected_pieces"):
			return child.get_connected_pieces()
	return []


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
