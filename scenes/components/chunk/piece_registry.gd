class_name PieceRegistry
extends RefCounted

# PieceRegistry - chunk に置いたピースと、それが占めるマスの対応を持つ。
# 「どのマスが埋まっているか」はここだけで持つ（HexGrid は chunk にどのマスがあるかだけを持つ）。
# 占めるマスは置いたときのものを覚えておき、ピースの形から計算し直さない。

# マス → ピース
var _piece_at: Dictionary[Vector2i, Node] = {}
# ピースのインスタンスID → {"base": 起点のマス, "hexes": 占めるマス}
var _placements: Dictionary[int, Dictionary] = {}


func register(piece: Node, base_hex: Vector2i, occupied_hexes: Array) -> void:
	var hexes: Array[Vector2i] = []
	hexes.assign(occupied_hexes)
	_placements[piece.get_instance_id()] = {"base": base_hex, "hexes": hexes}
	for hex in occupied_hexes:
		_piece_at[hex] = piece


# 置いたときに占めたマスをすべて空ける
func unregister(piece: Node) -> void:
	var placement = _placements.get(piece.get_instance_id())
	if placement == null:
		return
	for hex in placement["hexes"]:
		_piece_at.erase(hex)
	_placements.erase(piece.get_instance_id())


func has_piece_at(hex: Vector2i) -> bool:
	return _piece_at.has(hex)


func get_piece_at_hex(hex: Vector2i) -> Node:
	return _piece_at.get(hex, null)


# 登録されていないピースなら null
func get_base_hex(piece: Node) -> Variant:
	var placement = _placements.get(piece.get_instance_id())
	return placement["base"] if placement != null else null


# 登録されていないピースなら空
func get_occupied_hexes(piece: Node) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var placement = _placements.get(piece.get_instance_id())
	if placement != null:
		result.assign(placement["hexes"])
	return result


func get_all_pieces() -> Array:
	var seen := {}
	var result := []
	for piece in _piece_at.values():
		if not seen.has(piece):
			seen[piece] = true
			result.append(piece)
	return result


func clear() -> void:
	_piece_at.clear()
	_placements.clear()
