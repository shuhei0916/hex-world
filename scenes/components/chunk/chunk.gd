# gdlint:disable=max-public-methods
@tool
class_name Chunk
extends Node2D

# Chunk - グリッドの外部API・ピース管理・隣接判定を管理する

signal grid_updated(hexes: Array[Hex])
signal piece_placed(piece: Piece)
signal piece_removed

const RESOURCE_COLORS = {
	"iron_ore": Color("#8B6914"),
}

@export var grid_radius: int = 4:
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree():
			return
		_update_grid_visuals()

var layout: Layout

var _hex_grid = preload("res://scenes/components/chunk/hex_grid.gd").new()
var _registry = preload("res://scenes/components/chunk/piece_registry.gd").new()
var _neighbor_manager = preload("res://scenes/components/chunk/neighbor_manager.gd").new()
var _renderer: GridRenderer
var _drawn_hexes: Array[Hex] = []
var _resources: Dictionary = {}


func _init():
	layout = Layout.make_default()
	_neighbor_manager.setup(_registry, _hex_grid)


func _ready():
	_renderer = preload("res://scenes/components/chunk/grid_renderer.gd").new()
	_renderer.setup(layout)
	add_child(_renderer)
	_update_grid_visuals()


func register_grid_hex(hex: Hex):
	_hex_grid.register_grid_hex(hex)


func is_inside_grid(hex: Hex) -> bool:
	return _hex_grid.is_inside_grid(hex)


func is_occupied(hex: Hex) -> bool:
	return _hex_grid.is_occupied(hex)


func occupy(hex: Hex):
	_hex_grid.occupy(hex)


func can_place(shape: Array, base_hex: Hex) -> bool:
	return _hex_grid.can_place(shape, base_hex)


func place_piece(packed_scene: PackedScene, base_hex: Hex, rotation: int = 0):
	var piece = packed_scene.instantiate()
	piece.position = hex_to_pixel(base_hex)
	add_child(piece)
	piece.setup(rotation)

	var occupied_hexes: Array[Hex] = []
	for offset in piece.get_hex_shape():
		var target = Hex.add(base_hex, offset)
		occupy(target)
		occupied_hexes.append(target)

	_registry.register(piece, base_hex, occupied_hexes)
	_neighbor_manager.update_connections_around(piece)
	_apply_mining_constraint(piece, occupied_hexes)
	piece_placed.emit(piece)


func remove_piece_at(target_hex: Hex) -> bool:
	var piece = _registry.get_piece_at_hex(target_hex)
	if piece == null:
		return false

	if piece.piece_type == PieceData.Type.HUB:
		return false

	if not is_instance_valid(piece) or not piece is Node:
		_registry.unregister(piece, [target_hex])
		return false

	var hexes_to_remove = _registry.get_occupied_hexes(piece)

	for hex in hexes_to_remove:
		_hex_grid.unoccupy(hex)

	# 隣接更新の前にマップから削除する（削除済みピースが接続先として残らないようにするため）
	_registry.unregister(piece, hexes_to_remove)
	_neighbor_manager.update_connections_around(piece, hexes_to_remove)

	piece.queue_free()
	piece_removed.emit()
	return true


func clear_grid():
	_hex_grid.clear_grid()
	_registry.clear()


func get_piece_at_hex(hex: Hex) -> Piece:
	return _registry.get_piece_at_hex(hex)


func get_piece_count() -> int:
	return _registry.get_all_pieces().size()


func get_base_hex(piece: Piece) -> Hex:
	return _registry.get_base_hex(piece)


func get_neighbor_piece(hex: Hex, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not is_inside_grid(neighbor_hex):
		return null
	return get_piece_at_hex(neighbor_hex)


func _update_grid_visuals():
	create_hex_grid(grid_radius)
	if _renderer:
		_renderer.draw_grid(_drawn_hexes)


func create_hex_grid(radius: int):
	grid_radius = radius
	_drawn_hexes.clear()

	for q in range(-radius, radius + 1):
		var r1 = max(-radius, -q - radius)
		var r2 = min(radius, -q + radius)
		for r in range(r1, r2 + 1):
			var hex = Hex.new(q, r)
			_drawn_hexes.append(hex)

	for hex in _drawn_hexes:
		register_grid_hex(hex)

	grid_updated.emit(_drawn_hexes)


func get_grid_hex_count() -> int:
	return _drawn_hexes.size()


func hex_to_pixel(hex: Hex) -> Vector2:
	return Layout.hex_to_pixel(layout, hex)


func find_hex_tile(target_hex: Hex) -> HexTile:
	if _renderer:
		return _renderer.find_hex_tile(target_hex)
	return null


func get_outer_hexes() -> Array[Hex]:
	var result: Array[Hex] = []
	for hex in _drawn_hexes:
		var max_coord = max(abs(hex.q), abs(hex.r), abs(hex.s))
		if max_coord == grid_radius:
			result.append(hex)
	return result


func mark_resource_hex(hex: Hex, resource_type: String):
	_resources[Hex.to_key(hex)] = resource_type
	var tile = find_hex_tile(hex)
	if tile and resource_type in RESOURCE_COLORS:
		tile.set_color(RESOURCE_COLORS[resource_type])


func get_hex_resource(hex: Hex) -> String:
	return _resources.get(Hex.to_key(hex), "")


func get_inner_hexes() -> Array[Hex]:
	var result: Array[Hex] = []
	for hex in _drawn_hexes:
		var max_coord = max(abs(hex.q), abs(hex.r), abs(hex.s))
		if max_coord < grid_radius:
			result.append(hex)
	return result


func generate_ore_deposits(count: int):
	var inner = get_inner_hexes()
	if inner.is_empty():
		return
	var inner_set: Dictionary = {}
	for hex in inner:
		inner_set[Hex.to_key(hex)] = hex

	inner.shuffle()
	var cluster: Array[Hex] = [inner[0]]
	var cluster_set: Dictionary = {Hex.to_key(inner[0]): true}
	var frontier: Array[Hex] = [inner[0]]

	while cluster.size() < count and not frontier.is_empty():
		frontier.shuffle()
		var current = frontier.pop_back()
		for dir in range(6):
			var neighbor = Hex.neighbor(current, dir)
			var key = Hex.to_key(neighbor)
			if key in inner_set and not (key in cluster_set) and not (key in _resources):
				cluster.append(neighbor)
				cluster_set[key] = true
				frontier.append(neighbor)
				if cluster.size() >= count:
					break

	for hex in cluster:
		mark_resource_hex(hex, "iron_ore")


func _apply_mining_constraint(piece: Piece, occupied_hexes: Array[Hex]):
	if piece.piece_type != PieceData.Type.MINER:
		return
	var ore_count = 0
	for hex in occupied_hexes:
		if get_hex_resource(hex) == "iron_ore":
			ore_count += 1
	if ore_count == 0:
		piece.set_recipe(null)
	else:
		piece.set_output_multiplier(ore_count)


func place_hub(item_name: String, goal_count: int):
	var scene = load("res://scenes/components/piece/hub.tscn")
	place_piece(scene, Hex.new(0, 0))
	var piece = get_piece_at_hex(Hex.new(0, 0))
	piece.get_node("Hub").setup(item_name, goal_count)
