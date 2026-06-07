extends RefCounted

# NeighborManager - ピース間の出力ポート接続解決を担当する
# PieceRegistry と HexGrid への参照を受け取り、接続の計算・更新を行う

var _registry
var _hex_grid


func setup(registry, hex_grid) -> void:
	_registry = registry
	_hex_grid = hex_grid


func update_connections_around(piece: Piece, precalculated_hexes = null) -> void:
	_update_piece_neighbors(piece)

	var surrounding_pieces = {}
	var occupied_hexes = precalculated_hexes
	if occupied_hexes == null:
		occupied_hexes = _registry.get_occupied_hexes(piece)

	for hex in occupied_hexes:
		for direction in range(6):
			var neighbor = _get_neighbor_piece(hex, direction)
			if neighbor and neighbor != piece:
				surrounding_pieces[neighbor.get_instance_id()] = neighbor

	for p in surrounding_pieces.values():
		_update_piece_neighbors(p)


func _update_piece_neighbors(piece: Piece) -> void:
	if not is_instance_valid(piece):
		return

	var current_connections: Array[Piece] = []
	var occupied_hexes = _registry.get_occupied_hexes(piece)

	for hex in occupied_hexes:
		for direction in range(6):
			var neighbor = _get_neighbor_piece(hex, direction)
			if neighbor and neighbor != piece:
				if _is_physically_connected(piece, hex, direction):
					if not neighbor in current_connections:
						current_connections.append(neighbor)

	if piece.output:
		piece.output.connected_pieces = current_connections
		piece.output.try_push()

	_update_conveyor_input_direction(piece)


func _update_conveyor_input_direction(piece: Piece) -> void:
	if piece.piece_type != PieceData.Type.CONVEYOR:
		return
	var base_hex = _registry.get_base_hex(piece)
	if base_hex == null:
		piece.set_input_direction(-1)
		return
	for direction in range(6):
		var input_hex = Hex.neighbor(base_hex, direction)
		var neighbor = _registry.get_piece_at_hex(input_hex)
		if neighbor == null or neighbor == piece:
			continue
		var neighbor_base = _registry.get_base_hex(neighbor)
		if neighbor_base == null:
			continue
		for port in neighbor.get_output_ports():
			var abs_port_hex = Hex.add(neighbor_base, port.hex)
			var port_target = Hex.neighbor(abs_port_hex, port.direction)
			if Hex.equals(port_target, base_hex):
				piece.set_input_direction(direction)
				return
	piece.set_input_direction(-1)


func _is_physically_connected(source: Piece, source_hex: Hex, direction: int) -> bool:
	var base_hex = _registry.get_base_hex(source)
	if base_hex == null:
		return false

	for port in source.get_output_ports():
		var absolute_port_hex = Hex.add(base_hex, port.hex)
		if Hex.equals(absolute_port_hex, source_hex) and port.direction == direction:
			return true
	return false


func _get_neighbor_piece(hex: Hex, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not _hex_grid.is_inside_grid(neighbor_hex):
		return null
	return _registry.get_piece_at_hex(neighbor_hex)
