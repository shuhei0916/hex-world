class_name NeighborManager
extends RefCounted

# NeighborManager - ピース間の出力ポート接続解決を担当する
# PieceRegistry と HexGrid への参照を受け取り、接続の計算・更新を行う

var _registry: PieceRegistry
var _hex_grid: HexGrid


func setup(registry: PieceRegistry, hex_grid: HexGrid) -> void:
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
	# 橋の出力はチャンク間配線（World が管理）専用。
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
				if _feeds_neighbor(piece, hex, direction):
					if not neighbor in current_connections:
						current_connections.append(neighbor)
						current_directions.append(direction)

	piece.set_connected_pieces(current_connections, current_directions)
	if piece.is_conveyor():
		# つながる先が無くなったら出口は空で伝える（ベルトは自分の出口へ向けて描く）
		piece.show_belt_directions(_belt_input_directions(piece), current_directions)


# 合流では入力元が複数になる。ドラッグで決まった入力方向がつながっていればそれを主入力（先頭）にする
func _belt_input_directions(piece: Piece) -> Array:
	var directions := feeding_directions(piece)
	if piece.input_direction in directions:
		directions.erase(piece.input_direction)
		directions.push_front(piece.input_direction)
	return directions


# 1マスのピースへ流し込んでくる入力元の方向（0-5）。送り出しの判定（_feeds_neighbor）を逆向きに使う
func feeding_directions(piece: Piece) -> Array:
	var directions: Array = []
	var base_hex = _registry.get_base_hex(piece)
	if base_hex == null:
		return directions
	for direction in range(6):
		var input_hex = Hex.neighbor(base_hex, direction)
		var neighbor = _registry.get_piece_at_hex(input_hex)
		if neighbor == null or neighbor == piece:
			continue
		if _feeds_neighbor(neighbor, input_hex, (direction + 3) % 6):
			directions.append(direction)
	return directions


# source が、自分の占めるマス from_hex から direction の隣のマスへアイテムを送り出すか。
# from_hex を渡すのは、複数マスを占める施設では排出口のあるマスからしか出さないため
# （1マスのコンベアでは起点のマスと同じ）。送り出すのは次のどれか:
# - 排出口（出力ポート）がそのマスのその辺にある
# - 送り手がコンベアで、隣のコンベアがこちら側から受け取る向きにある（分岐）
# ただし、隣のベルトの出口がこちらを向いていれば送らない（向かい合わせのベルトは押し付け合わず止まる）
func _feeds_neighbor(source: Piece, from_hex: Vector2i, direction: int) -> bool:
	if _registry.get_base_hex(source) == null:
		return false
	var neighbor = _get_neighbor_piece(from_hex, direction)
	if _outputs_toward(neighbor, (direction + 3) % 6):
		return false

	if {"hex": from_hex, "direction": direction} in _registry.get_output_ports_on_grid(source):
		return true

	# 施設は排出口からしか出さないので、分岐は送り手がコンベアのときだけ
	return _is_conveyor(source) and _conveyor_receives_from(neighbor, direction)


# conveyor が、direction の向きに進んでくるアイテムを受け取る配置か。ベルトは自分の入力側からしか受け取らない。
# - 入力側が決まっている: 入力側（input_direction）が送り手の方を向いている
# - 入力側が未指定（直進）: 出口が同じ direction を向いている（真後ろが入力側）
func _conveyor_receives_from(conveyor: Piece, direction: int) -> bool:
	return _is_conveyor(conveyor) and conveyor.belt_input_side() == (direction + 3) % 6


# piece がコンベアで、出口が direction を向いているか
func _outputs_toward(piece: Piece, direction: int) -> bool:
	return _is_conveyor(piece) and piece.output_direction() == direction


func _is_conveyor(piece: Piece) -> bool:
	return piece != null and piece.is_conveyor()


func _get_neighbor_piece(hex: Vector2i, direction: int) -> Piece:
	var neighbor_hex = Hex.neighbor(hex, direction)
	if not _hex_grid.is_inside_grid(neighbor_hex):
		return null
	return _registry.get_piece_at_hex(neighbor_hex)
