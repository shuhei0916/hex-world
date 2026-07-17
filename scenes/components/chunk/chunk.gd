# gdlint:disable=max-public-methods
@tool
class_name Chunk
extends Node2D

# Chunk - グリッドの外部API・ピース管理・隣接判定を管理する

signal grid_updated(hexes: Array[Hex])
signal piece_placed(piece: Piece)
signal piece_removed

@export var grid_radius: int = 5:
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
var _resources = preload("res://scenes/components/chunk/chunk_resources.gd").new()
var _hint_hexes: Array = []


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


func can_place(shape: Array, base_hex: Hex, piece_type: int = -1) -> bool:
	if _requires_edge(piece_type) and get_edge_direction(base_hex) == -1:
		return false
	return _hex_grid.can_place(shape, base_hex)


func _requires_edge(piece_type: int) -> bool:
	return piece_type == PieceData.Type.SENDER or piece_type == PieceData.Type.RECEIVER


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


func get_all_pieces() -> Array:
	return _registry.get_all_pieces()


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


func get_all_hexes() -> Array[Hex]:
	return _drawn_hexes.duplicate()


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


# 辺ヘックスが属する辺の方向（0〜5）を返す。角・内側ヘックスは -1。
# 辺は「座標1つだけが±R」で判定し、その座標の符号と一致する成分を持つ方向に対応させる。
# 対辺は正確に逆方向（+3 mod 6）になる。
func get_edge_direction(hex: Hex) -> int:
	var on_edge := [
		hex.q == grid_radius,  # E(0)
		hex.r == -grid_radius,  # NE(1)
		hex.s == grid_radius,  # NW(2)
		hex.q == -grid_radius,  # W(3)
		hex.r == grid_radius,  # SW(4)
		hex.s == -grid_radius,  # SE(5)
	]
	if on_edge.count(true) != 1:
		return -1
	return on_edge.find(true)


# Receiver の設置候補位置をハイライトする。呼ぶたびに前回分はクリアされる。
func show_receiver_hints(hexes: Array):
	for hex in _hint_hexes:
		var tile = find_hex_tile(hex)
		if tile:
			tile.set_highlight(false)
	_hint_hexes = hexes.duplicate()
	for hex in _hint_hexes:
		var tile = find_hex_tile(hex)
		if tile:
			tile.set_highlight(true)


func mark_resource_hex(hex: Hex, resource_type: String):
	_resources.mark_resource_hex(hex, resource_type)
	var tile = find_hex_tile(hex)
	if tile and resource_type in _resources.RESOURCE_COLORS:
		tile.set_color(_resources.RESOURCE_COLORS[resource_type])


func get_hex_resource(hex: Hex) -> String:
	return _resources.get_hex_resource(hex)


func get_inner_hexes() -> Array[Hex]:
	var result: Array[Hex] = []
	for hex in _drawn_hexes:
		var max_coord = max(abs(hex.q), abs(hex.r), abs(hex.s))
		if max_coord < grid_radius:
			result.append(hex)
	return result


func generate_ore_deposits(count: int):
	var cluster = _resources.generate_ore_deposits(count, get_inner_hexes(), _hex_grid)
	for hex in cluster:
		var tile = find_hex_tile(hex)
		if tile:
			tile.set_color(_resources.RESOURCE_COLORS["iron_ore"])


func _apply_mining_constraint(piece: Piece, occupied_hexes: Array[Hex]):
	_resources.apply_mining_constraint(piece, occupied_hexes)


func place_hub(item_name: String, goal_count: int):
	var scene = load("res://scenes/components/piece/hub.tscn")
	place_piece(scene, Hex.new(0, 0))
	var piece = get_piece_at_hex(Hex.new(0, 0))
	piece.get_node("Hub").setup(item_name, goal_count)
