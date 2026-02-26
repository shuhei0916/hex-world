class_name HexGrid
extends RefCounted

# HexGrid - 論理グリッド状態のみを管理する
# 登録済み座標と占有済み座標を辞書で保持し、クエリと変更を提供する

var _registered_hexes: Dictionary = {}
var _occupied_hexes: Dictionary = {}


func register_grid_hex(hex: Hex):
	_registered_hexes[hex_to_key(hex)] = hex


func is_inside_grid(hex: Hex) -> bool:
	return _registered_hexes.has(hex_to_key(hex))


func is_occupied(hex: Hex) -> bool:
	return _occupied_hexes.has(hex_to_key(hex))


func occupy(hex: Hex):
	_occupied_hexes[hex_to_key(hex)] = hex


func unoccupy(hex: Hex):
	_occupied_hexes.erase(hex_to_key(hex))


func occupy_many(hexes: Array[Hex]):
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


func clear_grid():
	_registered_hexes.clear()
	_occupied_hexes.clear()


func hex_to_key(hex: Hex) -> String:
	return "%d,%d,%d" % [hex.q, hex.r, hex.s]
