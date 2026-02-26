@tool
class_name Island
extends Node2D

# Island - グリッドの外部API・ピース管理・隣接判定・詳細モードを管理する

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
var is_detail_mode_enabled: bool = false

# 論理グリッドの状態
var _hex_grid = preload("res://scenes/components/island/hex_grid.gd").new()
var _renderer: Node2D  # GridRenderer（preload で実体化）
var _hex_to_piece_map: Dictionary = {}  # Hex座標 -> Pieceノードのマッピング
var _piece_to_base_hex_map: Dictionary = {}  # PieceインスタンスID -> 起点Hex座標
var _drawn_hexes: Array[Hex] = []


func _init():
	_hex_to_piece_map.clear()
	_piece_to_base_hex_map.clear()

	layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2(0.0, 0.0))


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


func occupy_many(hexes: Array):
	_hex_grid.occupy_many(hexes)


func can_place(shape: Array, base_hex: Hex) -> bool:
	return _hex_grid.can_place(shape, base_hex)


func place_piece(shape: Array, base_hex: Hex, data: PieceData, rotation: int = 0):
	var effective_color = data.color

	var occupied_hexes: Array[Hex] = []
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)
		occupied_hexes.append(target)

		# 配置されたHexTileの色を更新
		_renderer.set_tile_color(target, effective_color)

	# Pieceノードを生成
	var piece = piece_scene.instantiate()

	# 座標設定（基準Hexの位置に配置）
	piece.position = hex_to_pixel(base_hex)

	# シーンツリーに追加
	add_child(piece)

	# データセットアップ
	piece.setup(data, rotation)

	# 詳細モードの設定を適用
	piece.set_detail_mode(is_detail_mode_enabled)

	# マップに登録
	for hex in occupied_hexes:
		var key = _hex_grid.hex_to_key(hex)
		_hex_to_piece_map[key] = piece

	_piece_to_base_hex_map[piece.get_instance_id()] = base_hex

	# 隣接情報を更新
	_update_neighbors_around_piece(piece)


func remove_piece_at(target_hex: Hex) -> bool:
	var key = _hex_grid.hex_to_key(target_hex)
	if not _hex_to_piece_map.has(key):
		return false

	var piece = _hex_to_piece_map[key]

	if not is_instance_valid(piece) or not piece is Node:
		_hex_to_piece_map.erase(key)
		return false

	var hexes_to_remove = get_piece_occupied_hexes(piece)

	for hex in hexes_to_remove:
		var h_key = _hex_grid.hex_to_key(hex)
		_hex_to_piece_map.erase(h_key)
		_unplace_single_hex(hex)

	_piece_to_base_hex_map.erase(piece.get_instance_id())

	# 削除されるピースの周囲の隣接情報を更新
	_update_neighbors_around_piece(piece, hexes_to_remove)

	piece.queue_free()
	return true


func _unplace_single_hex(hex: Hex):
	_hex_grid.unoccupy(hex)
	_renderer.reset_tile_color(hex)


func clear_grid():
	_hex_grid.clear_grid()
	_hex_to_piece_map.clear()


func _update_piece_neighbors(piece: Piece):
	if not is_instance_valid(piece):
		return

	var current_connections: Array[Piece] = []
	var occupied_hexes = get_piece_occupied_hexes(piece)

	for hex in occupied_hexes:
		for direction in range(6):
			var neighbor = get_neighbor_piece(hex, direction)
			if neighbor and neighbor != piece:
				# ポート接続の判定
				if _is_physically_connected(piece, hex, direction, neighbor):
					if not neighbor in current_connections:
						current_connections.append(neighbor)

	if piece.output:
		piece.output.connected_pieces = current_connections


func _is_physically_connected(
	source: Piece, source_hex: Hex, direction: int, _target: Piece
) -> bool:
	var base_hex = _piece_to_base_hex_map.get(source.get_instance_id())
	if base_hex == null:
		return false

	# sourceのsource_hexからdirection方向に出力ポートがあるか確認
	for port in source.get_output_ports():
		# ポートの相対座標を、配置時の基準座標を使って絶対座標に変換
		var absolute_port_hex = Hex.add(base_hex, port.hex)
		if Hex.equals(absolute_port_hex, source_hex) and port.direction == direction:
			return true
	return false


func _update_neighbors_around_piece(piece: Piece, precalculated_hexes = null):
	# このピース自身の隣人を更新
	_update_piece_neighbors(piece)

	# このピースの周囲にいるピースたちの隣人リストも更新（自分が入る/消えるため）
	var surrounding_pieces = {}
	var occupied_hexes = precalculated_hexes
	if occupied_hexes == null:
		occupied_hexes = get_piece_occupied_hexes(piece)

	for hex in occupied_hexes:
		for direction in range(6):
			var neighbor = get_neighbor_piece(hex, direction)
			if neighbor and neighbor != piece:
				surrounding_pieces[neighbor.get_instance_id()] = neighbor

	for p in surrounding_pieces.values():
		_update_piece_neighbors(p)


func get_piece_at_hex(hex: Hex) -> Piece:
	var key = _hex_grid.hex_to_key(hex)
	return _hex_to_piece_map.get(key, null)


func get_piece_occupied_hexes(piece: Piece) -> Array[Hex]:
	var result: Array[Hex] = []
	var base_hex = _piece_to_base_hex_map.get(piece.get_instance_id())
	if base_hex == null:
		return []

	var shape = piece.get_hex_shape()
	for offset in shape:
		result.append(Hex.add(base_hex, offset))
	return result


func get_neighbor_piece(hex: Hex, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not is_inside_grid(neighbor_hex):
		return null
	return get_piece_at_hex(neighbor_hex)


func toggle_detail_mode():
	is_detail_mode_enabled = not is_detail_mode_enabled
	_update_all_pieces_detail_mode()


func _update_all_pieces_detail_mode():
	var processed_pieces = {}
	for key in _hex_to_piece_map:
		var piece = _hex_to_piece_map[key]
		if is_instance_valid(piece) and not processed_pieces.has(piece.get_instance_id()):
			piece.set_detail_mode(is_detail_mode_enabled)
			processed_pieces[piece.get_instance_id()] = true


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
