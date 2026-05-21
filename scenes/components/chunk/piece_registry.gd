extends RefCounted

# PieceRegistry - ピースのライフサイクル管理とHex座標マッピング
# _hex_to_piece_map: Hexキー → Piece
# _piece_to_base_hex_map: インスタンスID → 起点Hex

var _hex_to_piece_map: Dictionary = {}
var _piece_to_base_hex_map: Dictionary = {}


func register(piece: Node, base_hex: Hex, occupied_hexes: Array) -> void:
	_piece_to_base_hex_map[piece.get_instance_id()] = base_hex
	for hex in occupied_hexes:
		_hex_to_piece_map[_key(hex)] = piece


func unregister(piece: Node, occupied_hexes: Array) -> void:
	_piece_to_base_hex_map.erase(piece.get_instance_id())
	for hex in occupied_hexes:
		_hex_to_piece_map.erase(_key(hex))


func has_piece_at(hex: Hex) -> bool:
	return _hex_to_piece_map.has(_key(hex))


func get_piece_at_hex(hex: Hex) -> Node:
	return _hex_to_piece_map.get(_key(hex), null)


func get_base_hex(piece: Node) -> Hex:
	return _piece_to_base_hex_map.get(piece.get_instance_id(), null)


func get_occupied_hexes(piece: Node) -> Array:
	var result: Array[Hex] = []
	var base_hex = get_base_hex(piece)
	if base_hex == null:
		return result
	if not piece.has_method("get_hex_shape"):
		return result
	for offset in piece.get_hex_shape():
		result.append(Hex.add(base_hex, offset))
	return result


func get_all_pieces() -> Array:
	var seen = {}
	var result = []
	for piece in _hex_to_piece_map.values():
		var id = piece.get_instance_id()
		if not seen.has(id):
			seen[id] = true
			result.append(piece)
	return result


func clear() -> void:
	_hex_to_piece_map.clear()
	_piece_to_base_hex_map.clear()


func _key(hex: Hex) -> String:
	return Hex.to_key(hex)
