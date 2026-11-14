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
	# SENDER の出力はチャンク間配線（World が管理）専用。
	# チャンク内で配線すると World の配線を上書きしてしまうため対象外とする。
	if piece.piece_type == PieceData.Type.BRIDGE:
		return

	var current_connections: Array[Piece] = []
	var current_directions: Array[int] = []  # 各接続への出力方向(0-5)
	var occupied_hexes = _registry.get_occupied_hexes(piece)

	for hex in occupied_hexes:
		for direction in range(6):
			var neighbor = _get_neighbor_piece(hex, direction)
			if neighbor and neighbor != piece:
				if _is_physically_connected(piece, hex, direction):
					if not neighbor in current_connections:
						current_connections.append(neighbor)
						current_directions.append(direction)

	piece.set_connected_pieces(current_connections, current_directions)

	_update_conveyor_input_direction(piece)
	_update_conveyor_output_directions(piece, current_directions)


func _update_conveyor_output_directions(piece: Piece, directions: Array[int]) -> void:
	var visuals = piece.get_node_or_null("ConveyorVisuals")
	if visuals == null or directions.is_empty():
		return
	visuals.set_output_directions(directions)


func _update_conveyor_input_direction(piece: Piece) -> void:
	var visuals = piece.get_node_or_null("ConveyorVisuals")
	if visuals == null:
		return
	var base_hex = _registry.get_base_hex(piece)
	if base_hex == null:
		visuals.set_input_direction(-1)
		return
	# 出力の配線（_is_physically_connected）と同じ判定で、流し込んでくる入力元をすべて探す。
	# 合流では複数になる。ドラッグで決まった入力方向がつながっていればそれを主入力にする。
	var directions: Array = []
	for direction in range(6):
		var input_hex = Hex.neighbor(base_hex, direction)
		var neighbor = _registry.get_piece_at_hex(input_hex)
		if neighbor == null or neighbor == piece:
			continue
		if _is_physically_connected(neighbor, input_hex, (direction + 3) % 6):
			directions.append(direction)
	if piece.input_direction in directions:
		directions.erase(piece.input_direction)
		directions.push_front(piece.input_direction)
	visuals.set_input_directions(directions)


func _is_physically_connected(source: Piece, source_hex: Hex, direction: int) -> bool:
	var base_hex = _registry.get_base_hex(source)
	if base_hex == null:
		return false

	for port in source.get_output_ports():
		var absolute_port_hex = Hex.add(base_hex, port.hex)
		if Hex.equals(absolute_port_hex, source_hex) and port.direction == direction:
			return true

	# コンベア同士の自然な分岐: 隣のコンベアの出力方向が A→C の向きと一致するとき接続
	var neighbor = _get_neighbor_piece(source_hex, direction)
	if _is_downstream_conveyor(neighbor, direction):
		return true

	return false


# 隣のコンベア C が source から受け取る配置かどうか。
# - 直進: C の出力方向が source→C の向きと一致する
# - 曲がり: C の入力側（input_direction）が source を向いている
func _is_downstream_conveyor(neighbor: Piece, direction: int) -> bool:
	if neighbor == null or neighbor.get_node_or_null("ConveyorVisuals") == null:
		return false
	if neighbor.input_direction == (direction + 3) % 6:
		return true
	var ports = neighbor.get_output_ports()
	return not ports.is_empty() and ports[0]["direction"] == direction


func _get_neighbor_piece(hex: Hex, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not _hex_grid.is_inside_grid(neighbor_hex):
		return null
	return _registry.get_piece_at_hex(neighbor_hex)
