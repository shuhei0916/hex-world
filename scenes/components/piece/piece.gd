@tool
class_name Piece
extends Node2D

signal recipe_changed(recipe: Recipe)
signal shape_changed

const HEX_TILE_SCENE = preload("res://scenes/components/hex_tile/hex_tile.tscn")
const FORWARD_TEXTURE = preload("res://scenes/components/piece/forward.png")
const PORT_OFFSET = 35.0
const ARROW_COLOR = Color(0.9607843, 0.6509804, 0.13725491, 1)
const CONNECTED_COLOR = Color(0.5, 1.0, 0.5, 1)

# シーンに保存されるピース定義データ（各 .tscn に直接設定する）
@export var piece_name: String = ""
@export_multiline var piece_description: String = ""
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
var _connection_direction: int = -1

# コンポーネント
# 受け入れ口は get_acceptor()（can_accept_item+add_item を持つ子をダックタイピング）で解決する。
@onready var ejector: ItemEjector = get_node_or_null("ItemEjector")
@onready var crafter: Crafter = get_node_or_null("Crafter")


func _ready():
	if Engine.is_editor_hint():
		_refresh_output_arrow()
		_create_hex_tiles()
		return
	if crafter and ejector:
		crafter.setup(ejector)


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
	# ベルトを描くコンベアは画像自体が見た目を担うので基礎タイルは描かない。
	if _is_belt():
		return
	var layout = Layout.make_default()
	var tile_z := 10
	for hex in get_hex_shape():
		var tile = HEX_TILE_SCENE.instantiate()
		tile.position = Layout.hex_to_pixel(layout, hex)
		tile.z_index = tile_z
		tile.z_as_relative = false
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
	_refresh_output_arrow()
	_create_hex_tiles()
	shape_changed.emit()


func set_recipe(recipe: Recipe):
	if crafter:
		crafter.set_recipe(recipe)
	recipe_changed.emit(recipe)


func set_output_multiplier(n: int):
	if crafter:
		crafter.output_multiplier = n


func add_item(item_name: String, amount: int):
	var acc = get_acceptor()
	if acc:
		acc.add_item(item_name, amount)


func add_to_output(item_name: String, amount: int):
	if ejector:
		ejector.add_item(item_name, amount)


func get_item_count(item_name: String) -> int:
	var count = 0
	for child in get_children():
		if child.has_method("get_item_count"):
			count += child.get_item_count(item_name)
	return count


func tick(delta: float):
	# 全 tick を Piece に集約する。まず crafter(生産)→次に他のロジック(ejector/conveyor)。
	# これにより同一フレーム内で「生産→排出」が流れ、子の自走 _process との二重 tick も避ける。
	if crafter:
		crafter.tick(delta)
	for child in get_children():
		if child != crafter and child.has_method("tick"):
			child.tick(delta)


func get_hex_shape() -> Array[Hex]:
	var hexes: Array[Hex] = []
	for v in piece_shape:
		hexes.append(Hex.from_offset_rotated(v, rotation_state))
	return hexes


func rotate_cw():
	rotation_state = (rotation_state + 1) % 6
	_refresh_output_arrow()
	_create_hex_tiles()
	shape_changed.emit()


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


func is_replaceable() -> bool:
	return _is_belt()


func _is_belt() -> bool:
	# ConveyorVisuals を持つのはベルトを描くコンベアのみ。
	return get_node_or_null("ConveyorVisuals") != null


func _refresh_output_arrow():
	if _output_arrow:
		_output_arrow.queue_free()
		_output_arrow = null
	if _output_arrow2:
		_output_arrow2.queue_free()
		_output_arrow2 = null
	# ベルト画像自体が方向を示すので、コンベアには矢印を出さない。
	if _is_belt():
		return
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
	var acc = get_acceptor()
	return acc != null and acc.can_accept_item(item_name)


func set_connected_pieces(pieces: Array, directions: Array = []) -> void:
	for child in get_children():
		if child.has_method("set_connected_pieces"):
			child.set_connected_pieces(pieces, directions)
			break
	_connection_direction = directions[0] if not directions.is_empty() else -1
	_refresh_connection_indicator()


func get_connected_pieces() -> Array:
	for child in get_children():
		if child.has_method("get_connected_pieces"):
			return child.get_connected_pieces()
	return []


func has_connected_piece() -> bool:
	return not get_connected_pieces().is_empty()


func _refresh_connection_indicator() -> void:
	if piece_type != PieceData.Type.SENDER and piece_type != PieceData.Type.RECEIVER:
		return
	# modulate は子にも伝播し矢印まで緑に染めてしまうため、タイル側だけを個別に着色する。
	var color = CONNECTED_COLOR if has_connected_piece() else Color(1, 1, 1)
	for child in get_children():
		if child is HexTile:
			child.modulate = color
	_refresh_connection_arrow()


func _refresh_connection_arrow() -> void:
	var existing = get_node_or_null("ConnectionArrow")
	if existing:
		remove_child(existing)
		existing.queue_free()
	if piece_type != PieceData.Type.SENDER:
		return
	if not has_connected_piece() or _connection_direction < 0:
		return
	var arrow = make_output_arrow({"hex": Hex.new(0, 0, 0), "direction": _connection_direction})
	arrow.name = "ConnectionArrow"
	arrow.scale = Vector2(1.0, 1.0)
	arrow.position += Vector2(PORT_OFFSET, 0).rotated(arrow.rotation)
	arrow.z_index = 20
	arrow.z_as_relative = false
	add_child(arrow)


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
