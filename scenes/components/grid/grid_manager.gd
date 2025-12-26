@tool
class_name GridManager
extends Node2D

# GridManager - グリッドの論理的な状態と視覚的な表示を管理する
# Unity版のGridManager.csとGridDisplayの機能を統合

signal grid_updated(hexes: Array[Hex])

# 論理グリッドの状態
var _registered_hexes: Dictionary = {} 
var _occupied_hexes: Dictionary = {} 
var _hex_to_piece_map: Dictionary = {} # Hex座標 -> Pieceノードのマッピング

# 視覚グリッドの状態
var layout: Layout 
var _drawn_hexes: Array[Hex] = [] 
var hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
var piece_scene = preload("res://scenes/components/piece/piece.tscn")

@export var grid_radius: int = 4:
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree():
			return
		_update_grid_visuals()

func _init():
	_registered_hexes.clear()
	_occupied_hexes.clear()
	_hex_to_piece_map.clear()
	
	layout = Layout.new(
		Layout.layout_pointy,
		Vector2(42.0, 42.0),
		Vector2(0.0, 0.0)
	)

func _ready():
	_update_grid_visuals()

# ==============================================================================
# 論理グリッド管理
# ==============================================================================

func register_grid_hex(hex: Hex):
	var key = _hex_to_key(hex)
	_registered_hexes[key] = hex

func is_inside_grid(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return _registered_hexes.has(key)

func is_occupied(hex: Hex) -> bool:
	var key = _hex_to_key(hex)
	return _occupied_hexes.has(key)

func occupy(hex: Hex):
	var key = _hex_to_key(hex)
	_occupied_hexes[key] = hex

func occupy_many(hexes: Array):
	for hex in hexes:
		occupy(hex)

func can_place(shape: Array, base_hex: Hex) -> bool:
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		if not is_inside_grid(target):
			return false
		if is_occupied(target):
			return false
	return true

func place_piece(shape: Array, base_hex: Hex, piece_color: Color, piece_type: int = 0):
	var occupied_hexes: Array[Hex] = []
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)
		occupied_hexes.append(target)
		
		# 配置されたHexTileの色を更新
		var hex_tile = find_hex_tile(target)
		if hex_tile:
			hex_tile.set_color(piece_color)
	
	# Pieceノードを生成
	var piece = piece_scene.instantiate()
	
	# データセットアップ
	var data = {
		"type": piece_type,
		"hex_coordinates": occupied_hexes
	}
	if piece.has_method("setup"):
		piece.setup(data)
	
	# 座標設定（基準Hexの位置に配置）
	piece.position = hex_to_pixel(base_hex)
	
	# シーンツリーに追加
	add_child(piece)
	
	# マップに登録
	for hex in occupied_hexes:
		var key = _hex_to_key(hex)
		_hex_to_piece_map[key] = piece

func remove_piece_at(target_hex: Hex) -> bool:
	var key = _hex_to_key(target_hex)
	if not _hex_to_piece_map.has(key):
		return false
	
	var piece = _hex_to_piece_map[key]
	
	if not is_instance_valid(piece) or not piece is Node:
		_hex_to_piece_map.erase(key)
		return false

	var hexes_to_remove = []
	if "hex_coordinates" in piece:
		hexes_to_remove = piece.hex_coordinates
	
	for hex in hexes_to_remove:
		var h_key = _hex_to_key(hex)
		_hex_to_piece_map.erase(h_key)
		_unplace_single_hex(hex)
	
	piece.queue_free()
	return true

func _unplace_single_hex(hex: Hex):
	var key = _hex_to_key(hex)
	_occupied_hexes.erase(key)
	
	var hex_tile = find_hex_tile(hex)
	if hex_tile:
		hex_tile.reset_color()

# 旧メソッドを削除 (unplace_piece は不要になったため)

func clear_grid():
	_registered_hexes.clear()
	_occupied_hexes.clear()
	_hex_to_piece_map.clear()

func _hex_to_key(hex: Hex) -> String:
	return "%d,%d,%d" % [hex.q, hex.r, hex.s]

func get_piece_at_hex(hex: Hex) -> Piece:
	var key = _hex_to_key(hex)
	return _hex_to_piece_map.get(key, null)

func get_neighbor_piece(hex: Hex, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not is_inside_grid(neighbor_hex):
		return null
	return get_piece_at_hex(neighbor_hex)

# ==============================================================================
# 視覚グリッド管理
# ==============================================================================

func _update_grid_visuals():
	while get_child_count() > 0:
		var child = get_child(0)
		remove_child(child)
		child.queue_free()

	create_hex_grid(grid_radius)
	draw_grid()

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

func draw_grid():
	for i in range(_drawn_hexes.size()):
		var hex = _drawn_hexes[i]
		var world_pos = hex_to_pixel(hex)
		var hex_instance = hex_tile_scene.instantiate()
		hex_instance.position = world_pos
		add_child(hex_instance)
		hex_instance.setup_hex(hex)

func highlight_path(hex_path: Array[Hex]):
	clear_path_highlight()
	for hex in hex_path:
		var hex_tile = find_hex_tile(hex)
		if hex_tile:
			hex_tile.set_highlight(true)

func highlight_path_with_start(hex_path: Array[Hex], start_hex: Hex):
	clear_path_highlight()
	if start_hex:
		var start_tile = find_hex_tile(start_hex)
		if start_tile:
			start_tile.set_highlight(true)
	for hex in hex_path:
		var hex_tile = find_hex_tile(hex)
		if hex_tile:
			hex_tile.set_highlight(true)

func clear_path_highlight():
	for child in get_children():
		if child.has_method("set_highlight"):
			child.set_highlight(false)

func find_hex_tile(target_hex: Hex) -> HexTile:
	for child in get_children():
		if child is HexTile and child.hex_coordinate:
			if Hex.equals(child.hex_coordinate, target_hex):
				return child
	return null

func is_within_bounds(hex_coord: Hex) -> bool:
	if not hex_coord:
		return false
	var key = _hex_to_key(hex_coord)
	return _registered_hexes.has(key)
