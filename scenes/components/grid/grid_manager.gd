@tool
class_name GridManager
extends Node2D

# GridManager - グリッドの論理的な状態と視覚的な表示を管理する
# Unity版のGridManager.csとGridDisplayの機能を統合

signal grid_updated(hexes: Array[Hex])

@export var grid_radius: int = 4:
	set(value):
		if value == grid_radius:
			return
		grid_radius = value
		if not is_inside_tree():
			return
		_update_grid_visuals()

# 視覚グリッドの状態
var layout: Layout
var hex_tile_scene = preload("res://scenes/components/hex_tile/hex_tile.tscn")
var piece_scene = preload("res://scenes/components/piece/piece.tscn")
var is_detail_mode_enabled: bool = false

# 論理グリッドの状態
var _registered_hexes: Dictionary = {}
var _occupied_hexes: Dictionary = {}
var _hex_to_piece_map: Dictionary = {}  # Hex座標 -> Pieceノードのマッピング
var _piece_to_base_hex_map: Dictionary = {}  # PieceインスタンスID -> 起点Hex座標
var _drawn_hexes: Array[Hex] = []


func _init():
	_registered_hexes.clear()
	_occupied_hexes.clear()
	_hex_to_piece_map.clear()
	_piece_to_base_hex_map.clear()

	layout = Layout.new(Layout.layout_pointy, Vector2(42.0, 42.0), Vector2(0.0, 0.0))


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


func place_piece(
	shape: Array,
	base_hex: Hex,
	piece_color = null,
	piece_type: int = 0,
	rotation: int = 0,
	data_override: PieceDB.PieceData = null
):
	var effective_color = piece_color
	if effective_color == null:
		if data_override:
			effective_color = data_override.color
		else:
			var db_data = PieceDB.get_data(piece_type)
			if db_data:
				effective_color = db_data.color
			else:
				effective_color = Color.WHITE

	var occupied_hexes: Array[Hex] = []
	for offset in shape:
		var target = Hex.add(base_hex, offset)
		occupy(target)
		occupied_hexes.append(target)

		# 配置されたHexTileの色を更新
		var hex_tile = find_hex_tile(target)
		if hex_tile:
			hex_tile.set_color(effective_color)

	# Pieceノードを生成
	var piece = piece_scene.instantiate()

	# データセットアップ
	var data = {"type": piece_type, "rotation": rotation}
	if piece.has_method("setup"):
		piece.setup(data, data_override)

	# 座標設定（基準Hexの位置に配置）
	piece.position = hex_to_pixel(base_hex)

	# シーンツリーに追加
	add_child(piece)

	# 詳細モードの設定を適用
	if piece.has_method("set_detail_mode"):
		piece.set_detail_mode(is_detail_mode_enabled)

	# マップに登録
	for hex in occupied_hexes:
		var key = _hex_to_key(hex)
		_hex_to_piece_map[key] = piece

	_piece_to_base_hex_map[piece.get_instance_id()] = base_hex

	# 隣接情報を更新
	_update_neighbors_around_piece(piece)


func remove_piece_at(target_hex: Hex) -> bool:
	var key = _hex_to_key(target_hex)
	if not _hex_to_piece_map.has(key):
		return false

	var piece = _hex_to_piece_map[key]

	if not is_instance_valid(piece) or not piece is Node:
		_hex_to_piece_map.erase(key)
		return false

	var hexes_to_remove = get_piece_occupied_hexes(piece)

	for hex in hexes_to_remove:
		var h_key = _hex_to_key(hex)
		_hex_to_piece_map.erase(h_key)
		_unplace_single_hex(hex)

	_piece_to_base_hex_map.erase(piece.get_instance_id())

	# 削除されるピースの周囲の隣接情報を更新
	_update_neighbors_around_piece(piece, hexes_to_remove)

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

	piece.destinations = current_connections


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
	var key = _hex_to_key(hex)
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


# ==============================================================================
# 詳細表示モード管理
# ==============================================================================


func toggle_detail_mode():
	is_detail_mode_enabled = not is_detail_mode_enabled
	_update_all_pieces_detail_mode()


func _update_all_pieces_detail_mode():
	# ピースノードは子ノードとして存在するか、マップで管理されている
	# ここではマップの値（ピース参照）を使ってユニークなピースに対して設定を行う
	var processed_pieces = {}
	for key in _hex_to_piece_map:
		var piece = _hex_to_piece_map[key]
		if is_instance_valid(piece) and not processed_pieces.has(piece.get_instance_id()):
			if piece.has_method("set_detail_mode"):
				piece.set_detail_mode(is_detail_mode_enabled)
			processed_pieces[piece.get_instance_id()] = true


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
