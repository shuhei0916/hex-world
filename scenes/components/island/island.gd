@tool
class_name Island
extends Node2D

# Island - グリッドの外部API・ピース管理・隣接判定を管理する

signal grid_updated(hexes: Array[Hex])

@export var grid_radius: int = 4:
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree():
			return
		_update_grid_visuals()

var layout: Layout
var piece_scene = preload("res://scenes/components/piece/piece.tscn")

var _hex_grid = preload("res://scenes/components/island/hex_grid.gd").new()
var _registry = preload("res://scenes/components/island/piece_registry.gd").new()
var _neighbor_manager = preload("res://scenes/components/island/neighbor_manager.gd").new()
var _renderer: GridRenderer
var _drawn_hexes: Array[Hex] = []


func _init():
	layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2(0.0, 0.0))
	_neighbor_manager.setup(_registry, _hex_grid)


func _ready():
	_renderer = preload("res://scenes/components/island/grid_renderer.gd").new()
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


func occupy_many(hexes: Array[Hex]):
	_hex_grid.occupy_many(hexes)


func can_place(shape: Array, base_hex: Hex) -> bool:
	return _hex_grid.can_place(shape, base_hex)


func place_piece(shape: Array, base_hex: Hex, data: PieceData, rotation: int = 0):
	var occupied_hexes: Array[Hex] = []
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)
		occupied_hexes.append(target)
		_renderer.set_tile_color(target, data.color)

	var piece = (data.scene if data.scene else piece_scene).instantiate()
	piece.position = hex_to_pixel(base_hex)
	add_child(piece)
	piece.setup(data, rotation)

	_registry.register(piece, base_hex, occupied_hexes)
	_neighbor_manager.update_connections_around(piece)


func remove_piece_at(target_hex: Hex) -> bool:
	var piece = _registry.get_piece_at_hex(target_hex)
	if piece == null:
		return false

	if not is_instance_valid(piece) or not piece is Node:
		_registry.unregister(piece, [target_hex])
		return false

	var hexes_to_remove = get_piece_occupied_hexes(piece)

	for hex in hexes_to_remove:
		_hex_grid.unoccupy(hex)
		_renderer.reset_tile_color(hex)

	# 隣接更新の前にマップから削除する（削除済みピースが接続先として残らないようにするため）
	_registry.unregister(piece, hexes_to_remove)
	_neighbor_manager.update_connections_around(piece, hexes_to_remove)

	piece.queue_free()
	return true


func clear_grid():
	_hex_grid.clear_grid()
	_registry.clear()


func get_piece_at_hex(hex: Hex) -> Piece:
	return _registry.get_piece_at_hex(hex)


func get_piece_occupied_hexes(piece: Piece) -> Array[Hex]:
	var result: Array[Hex] = []
	var base_hex = _registry.get_base_hex(piece)
	if base_hex == null:
		return result
	for offset in piece.get_hex_shape():
		result.append(Hex.add(base_hex, offset))
	return result


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
